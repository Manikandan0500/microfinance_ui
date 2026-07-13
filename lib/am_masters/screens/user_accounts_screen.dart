import 'dart:async';
import '../models/access_privileges.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:html' as html;  // Web-only, safe because of kIsWeb guard
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_account_model.dart';
import '../services/user_account_service.dart';
import '../services/operational_log_service.dart';
import '../services/auth_service.dart';
import '../services/organization_service.dart';
import '../services/branch_service.dart';
import '../models/branch_model.dart';
import '../services/access_code_service.dart';
import '../models/access_code_model.dart';
import '../services/profile_service.dart';
import '../services/address_service.dart';
import '../Datas/countries.dart';
import '../widgets/audit_details_dialog.dart';
import '../widgets/bulk_upload_dialog.dart';
import '../widgets/custom_calendar_dialog.dart';

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import '../services/product_service.dart';
import '../services/program_service.dart';
import '../validation/Validation.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
const _kP     = Color(0xFF3D6EBE);
const _kPL    = Color(0xFFEEF3FB);
const _kPB    = Color(0xFFC5D3E8);
const _kR     = Color(0xFFDC2626);
const _kRL    = Color(0xFFFEF2F2);
const _kRB    = Color(0xFFFECACA);
const _kG     = Color(0xFF16A34A);
const _kGL    = Color(0xFFDCFCE7);
const _kGB    = Color(0xFFBBF7D0);
const _kO     = Color(0xFFF97316);
const _kOB    = Color(0xFFFED7AA);
const _kOBG   = Color(0xFFFFF7ED);
const _kOT    = Color(0xFFC2410C);
const _kWarnBG = Color(0xFFFFFBEB);
const _kWarnB  = Color(0xFFFDE68A);
const _kWarnT  = Color(0xFFB45309);
const _kText   = Color(0xFF1E293B);
const _kMuted  = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kSurface = Color(0xFFF8FAFC);

enum _ViewMode { list, create, edit, view, delete, bulkUpload }

// ── Country data (full A-Z list with mobileLength) ────────────────────────────
class _CountryInfo {
  final String code;
  final String name;
  final String flag;
  final String dialCode;
  final int mobileLength;
  const _CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
    this.mobileLength = 10,
  });
}

const List<_CountryInfo> _kCountries = [
  _CountryInfo(code:'AF',name:'Afghanistan',            flag:'🇦🇫',dialCode:'93',  mobileLength:9),
  _CountryInfo(code:'AL',name:'Albania',                flag:'🇦🇱',dialCode:'355', mobileLength:9),
  _CountryInfo(code:'DZ',name:'Algeria',                flag:'🇩🇿',dialCode:'213', mobileLength:9),
  _CountryInfo(code:'AD',name:'Andorra',                flag:'🇦🇩',dialCode:'376', mobileLength:6),
  _CountryInfo(code:'AO',name:'Angola',                 flag:'🇦🇴',dialCode:'244', mobileLength:9),
  _CountryInfo(code:'AG',name:'Antigua and Barbuda',    flag:'🇦🇬',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'AR',name:'Argentina',              flag:'🇦🇷',dialCode:'54',  mobileLength:10),
  _CountryInfo(code:'AM',name:'Armenia',                flag:'🇦🇲',dialCode:'374', mobileLength:8),
  _CountryInfo(code:'AU',name:'Australia',              flag:'🇦🇺',dialCode:'61',  mobileLength:9),
  _CountryInfo(code:'AT',name:'Austria',                flag:'🇦🇹',dialCode:'43',  mobileLength:10),
  _CountryInfo(code:'AZ',name:'Azerbaijan',             flag:'🇦🇿',dialCode:'994', mobileLength:9),
  _CountryInfo(code:'BS',name:'Bahamas',                flag:'🇧🇸',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'BH',name:'Bahrain',                flag:'🇧🇭',dialCode:'973', mobileLength:8),
  _CountryInfo(code:'BD',name:'Bangladesh',             flag:'🇧🇩',dialCode:'880', mobileLength:10),
  _CountryInfo(code:'BB',name:'Barbados',               flag:'🇧🇧',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'BY',name:'Belarus',                flag:'🇧🇾',dialCode:'375', mobileLength:9),
  _CountryInfo(code:'BE',name:'Belgium',                flag:'🇧🇪',dialCode:'32',  mobileLength:9),
  _CountryInfo(code:'BZ',name:'Belize',                 flag:'🇧🇿',dialCode:'501', mobileLength:7),
  _CountryInfo(code:'BJ',name:'Benin',                  flag:'🇧🇯',dialCode:'229', mobileLength:8),
  _CountryInfo(code:'BT',name:'Bhutan',                 flag:'🇧🇹',dialCode:'975', mobileLength:8),
  _CountryInfo(code:'BO',name:'Bolivia',                flag:'🇧🇴',dialCode:'591', mobileLength:8),
  _CountryInfo(code:'BA',name:'Bosnia and Herzegovina', flag:'🇧🇦',dialCode:'387', mobileLength:8),
  _CountryInfo(code:'BW',name:'Botswana',               flag:'🇧🇼',dialCode:'267', mobileLength:7),
  _CountryInfo(code:'BR',name:'Brazil',                 flag:'🇧🇷',dialCode:'55',  mobileLength:11),
  _CountryInfo(code:'BN',name:'Brunei',                 flag:'🇧🇳',dialCode:'673', mobileLength:7),
  _CountryInfo(code:'BG',name:'Bulgaria',               flag:'🇧🇬',dialCode:'359', mobileLength:9),
  _CountryInfo(code:'BF',name:'Burkina Faso',           flag:'🇧🇫',dialCode:'226', mobileLength:8),
  _CountryInfo(code:'BI',name:'Burundi',                flag:'🇧🇮',dialCode:'257', mobileLength:8),
  _CountryInfo(code:'CV',name:'Cabo Verde',             flag:'🇨🇻',dialCode:'238', mobileLength:7),
  _CountryInfo(code:'KH',name:'Cambodia',               flag:'🇰🇭',dialCode:'855', mobileLength:9),
  _CountryInfo(code:'CM',name:'Cameroon',               flag:'🇨🇲',dialCode:'237', mobileLength:9),
  _CountryInfo(code:'CA',name:'Canada',                 flag:'🇨🇦',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'CF',name:'Central African Republic',flag:'🇨🇫',dialCode:'236',mobileLength:8),
  _CountryInfo(code:'TD',name:'Chad',                   flag:'🇹🇩',dialCode:'235', mobileLength:8),
  _CountryInfo(code:'CL',name:'Chile',                  flag:'🇨🇱',dialCode:'56',  mobileLength:9),
  _CountryInfo(code:'CN',name:'China',                  flag:'🇨🇳',dialCode:'86',  mobileLength:11),
  _CountryInfo(code:'CO',name:'Colombia',               flag:'🇨🇴',dialCode:'57',  mobileLength:10),
  _CountryInfo(code:'KM',name:'Comoros',                flag:'🇰🇲',dialCode:'269', mobileLength:7),
  _CountryInfo(code:'CG',name:'Congo',                  flag:'🇨🇬',dialCode:'242', mobileLength:9),
  _CountryInfo(code:'CR',name:'Costa Rica',             flag:'🇨🇷',dialCode:'506', mobileLength:8),
  _CountryInfo(code:'HR',name:'Croatia',                flag:'🇭🇷',dialCode:'385', mobileLength:9),
  _CountryInfo(code:'CU',name:'Cuba',                   flag:'🇨🇺',dialCode:'53',  mobileLength:8),
  _CountryInfo(code:'CY',name:'Cyprus',                 flag:'🇨🇾',dialCode:'357', mobileLength:8),
  _CountryInfo(code:'CZ',name:'Czech Republic',         flag:'🇨🇿',dialCode:'420', mobileLength:9),
  _CountryInfo(code:'DK',name:'Denmark',                flag:'🇩🇰',dialCode:'45',  mobileLength:8),
  _CountryInfo(code:'DJ',name:'Djibouti',               flag:'🇩🇯',dialCode:'253', mobileLength:8),
  _CountryInfo(code:'DM',name:'Dominica',               flag:'🇩🇲',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'DO',name:'Dominican Republic',     flag:'🇩🇴',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'EC',name:'Ecuador',                flag:'🇪🇨',dialCode:'593', mobileLength:9),
  _CountryInfo(code:'EG',name:'Egypt',                  flag:'🇪🇬',dialCode:'20',  mobileLength:10),
  _CountryInfo(code:'SV',name:'El Salvador',            flag:'🇸🇻',dialCode:'503', mobileLength:8),
  _CountryInfo(code:'GQ',name:'Equatorial Guinea',      flag:'🇬🇶',dialCode:'240', mobileLength:9),
  _CountryInfo(code:'ER',name:'Eritrea',                flag:'🇪🇷',dialCode:'291', mobileLength:7),
  _CountryInfo(code:'EE',name:'Estonia',                flag:'🇪🇪',dialCode:'372', mobileLength:8),
  _CountryInfo(code:'SZ',name:'Eswatini',               flag:'🇸🇿',dialCode:'268', mobileLength:8),
  _CountryInfo(code:'ET',name:'Ethiopia',               flag:'🇪🇹',dialCode:'251', mobileLength:9),
  _CountryInfo(code:'FJ',name:'Fiji',                   flag:'🇫🇯',dialCode:'679', mobileLength:7),
  _CountryInfo(code:'FI',name:'Finland',                flag:'🇫🇮',dialCode:'358', mobileLength:10),
  _CountryInfo(code:'FR',name:'France',                 flag:'🇫🇷',dialCode:'33',  mobileLength:9),
  _CountryInfo(code:'GA',name:'Gabon',                  flag:'🇬🇦',dialCode:'241', mobileLength:8),
  _CountryInfo(code:'GM',name:'Gambia',                 flag:'🇬🇲',dialCode:'220', mobileLength:7),
  _CountryInfo(code:'GE',name:'Georgia',                flag:'🇬🇪',dialCode:'995', mobileLength:9),
  _CountryInfo(code:'DE',name:'Germany',                flag:'🇩🇪',dialCode:'49',  mobileLength:10),
  _CountryInfo(code:'GH',name:'Ghana',                  flag:'🇬🇭',dialCode:'233', mobileLength:9),
  _CountryInfo(code:'GR',name:'Greece',                 flag:'🇬🇷',dialCode:'30',  mobileLength:10),
  _CountryInfo(code:'GD',name:'Grenada',                flag:'🇬🇩',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'GT',name:'Guatemala',              flag:'🇬🇹',dialCode:'502', mobileLength:8),
  _CountryInfo(code:'GN',name:'Guinea',                 flag:'🇬🇳',dialCode:'224', mobileLength:8),
  _CountryInfo(code:'GW',name:'Guinea-Bissau',          flag:'🇬🇼',dialCode:'245', mobileLength:7),
  _CountryInfo(code:'GY',name:'Guyana',                 flag:'🇬🇾',dialCode:'592', mobileLength:7),
  _CountryInfo(code:'HT',name:'Haiti',                  flag:'🇭🇹',dialCode:'509', mobileLength:8),
  _CountryInfo(code:'HN',name:'Honduras',               flag:'🇭🇳',dialCode:'504', mobileLength:8),
  _CountryInfo(code:'HU',name:'Hungary',                flag:'🇭🇺',dialCode:'36',  mobileLength:9),
  _CountryInfo(code:'IS',name:'Iceland',                flag:'🇮🇸',dialCode:'354', mobileLength:7),
  _CountryInfo(code:'IN',name:'India',                  flag:'🇮🇳',dialCode:'91',  mobileLength:10),
  _CountryInfo(code:'ID',name:'Indonesia',              flag:'🇮🇩',dialCode:'62',  mobileLength:10),
  _CountryInfo(code:'IR',name:'Iran',                   flag:'🇮🇷',dialCode:'98',  mobileLength:10),
  _CountryInfo(code:'IQ',name:'Iraq',                   flag:'🇮🇶',dialCode:'964', mobileLength:10),
  _CountryInfo(code:'IE',name:'Ireland',                flag:'🇮🇪',dialCode:'353', mobileLength:9),
  _CountryInfo(code:'IL',name:'Israel',                 flag:'🇮🇱',dialCode:'972', mobileLength:9),
  _CountryInfo(code:'IT',name:'Italy',                  flag:'🇮🇹',dialCode:'39',  mobileLength:10),
  _CountryInfo(code:'JM',name:'Jamaica',                flag:'🇯🇲',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'JP',name:'Japan',                  flag:'🇯🇵',dialCode:'81',  mobileLength:10),
  _CountryInfo(code:'JO',name:'Jordan',                 flag:'🇯🇴',dialCode:'962', mobileLength:9),
  _CountryInfo(code:'KZ',name:'Kazakhstan',             flag:'🇰🇿',dialCode:'7',   mobileLength:10),
  _CountryInfo(code:'KE',name:'Kenya',                  flag:'🇰🇪',dialCode:'254', mobileLength:9),
  _CountryInfo(code:'KI',name:'Kiribati',               flag:'🇰🇮',dialCode:'686', mobileLength:8),
  _CountryInfo(code:'KW',name:'Kuwait',                 flag:'🇰🇼',dialCode:'965', mobileLength:8),
  _CountryInfo(code:'KG',name:'Kyrgyzstan',             flag:'🇰🇬',dialCode:'996', mobileLength:9),
  _CountryInfo(code:'LA',name:'Laos',                   flag:'🇱🇦',dialCode:'856', mobileLength:9),
  _CountryInfo(code:'LV',name:'Latvia',                 flag:'🇱🇻',dialCode:'371', mobileLength:8),
  _CountryInfo(code:'LB',name:'Lebanon',                flag:'🇱🇧',dialCode:'961', mobileLength:8),
  _CountryInfo(code:'LS',name:'Lesotho',                flag:'🇱🇸',dialCode:'266', mobileLength:8),
  _CountryInfo(code:'LR',name:'Liberia',                flag:'🇱🇷',dialCode:'231', mobileLength:8),
  _CountryInfo(code:'LY',name:'Libya',                  flag:'🇱🇾',dialCode:'218', mobileLength:9),
  _CountryInfo(code:'LI',name:'Liechtenstein',          flag:'🇱🇮',dialCode:'423', mobileLength:7),
  _CountryInfo(code:'LT',name:'Lithuania',              flag:'🇱🇹',dialCode:'370', mobileLength:8),
  _CountryInfo(code:'LU',name:'Luxembourg',             flag:'🇱🇺',dialCode:'352', mobileLength:9),
  _CountryInfo(code:'MG',name:'Madagascar',             flag:'🇲🇬',dialCode:'261', mobileLength:9),
  _CountryInfo(code:'MW',name:'Malawi',                 flag:'🇲🇼',dialCode:'265', mobileLength:9),
  _CountryInfo(code:'MY',name:'Malaysia',               flag:'🇲🇾',dialCode:'60',  mobileLength:9),
  _CountryInfo(code:'MV',name:'Maldives',               flag:'🇲🇻',dialCode:'960', mobileLength:7),
  _CountryInfo(code:'ML',name:'Mali',                   flag:'🇲🇱',dialCode:'223', mobileLength:8),
  _CountryInfo(code:'MT',name:'Malta',                  flag:'🇲🇹',dialCode:'356', mobileLength:8),
  _CountryInfo(code:'MH',name:'Marshall Islands',       flag:'🇲🇭',dialCode:'692', mobileLength:7),
  _CountryInfo(code:'MR',name:'Mauritania',             flag:'🇲🇷',dialCode:'222', mobileLength:8),
  _CountryInfo(code:'MU',name:'Mauritius',              flag:'🇲🇺',dialCode:'230', mobileLength:8),
  _CountryInfo(code:'MX',name:'Mexico',                 flag:'🇲🇽',dialCode:'52',  mobileLength:10),
  _CountryInfo(code:'FM',name:'Micronesia',             flag:'🇫🇲',dialCode:'691', mobileLength:7),
  _CountryInfo(code:'MD',name:'Moldova',                flag:'🇲🇩',dialCode:'373', mobileLength:8),
  _CountryInfo(code:'MC',name:'Monaco',                 flag:'🇲🇨',dialCode:'377', mobileLength:8),
  _CountryInfo(code:'MN',name:'Mongolia',               flag:'🇲🇳',dialCode:'976', mobileLength:8),
  _CountryInfo(code:'ME',name:'Montenegro',             flag:'🇲🇪',dialCode:'382', mobileLength:8),
  _CountryInfo(code:'MA',name:'Morocco',                flag:'🇲🇦',dialCode:'212', mobileLength:9),
  _CountryInfo(code:'MZ',name:'Mozambique',             flag:'🇲🇿',dialCode:'258', mobileLength:9),
  _CountryInfo(code:'MM',name:'Myanmar',                flag:'🇲🇲',dialCode:'95',  mobileLength:9),
  _CountryInfo(code:'NA',name:'Namibia',                flag:'🇳🇦',dialCode:'264', mobileLength:9),
  _CountryInfo(code:'NR',name:'Nauru',                  flag:'🇳🇷',dialCode:'674', mobileLength:7),
  _CountryInfo(code:'NP',name:'Nepal',                  flag:'🇳🇵',dialCode:'977', mobileLength:10),
  _CountryInfo(code:'NL',name:'Netherlands',            flag:'🇳🇱',dialCode:'31',  mobileLength:9),
  _CountryInfo(code:'NZ',name:'New Zealand',            flag:'🇳🇿',dialCode:'64',  mobileLength:9),
  _CountryInfo(code:'NI',name:'Nicaragua',              flag:'🇳🇮',dialCode:'505', mobileLength:8),
  _CountryInfo(code:'NE',name:'Niger',                  flag:'🇳🇪',dialCode:'227', mobileLength:8),
  _CountryInfo(code:'NG',name:'Nigeria',                flag:'🇳🇬',dialCode:'234', mobileLength:10),
  _CountryInfo(code:'NO',name:'Norway',                 flag:'🇳🇴',dialCode:'47',  mobileLength:8),
  _CountryInfo(code:'OM',name:'Oman',                   flag:'🇴🇲',dialCode:'968', mobileLength:8),
  _CountryInfo(code:'PK',name:'Pakistan',               flag:'🇵🇰',dialCode:'92',  mobileLength:10),
  _CountryInfo(code:'PW',name:'Palau',                  flag:'🇵🇼',dialCode:'680', mobileLength:7),
  _CountryInfo(code:'PA',name:'Panama',                 flag:'🇵🇦',dialCode:'507', mobileLength:8),
  _CountryInfo(code:'PG',name:'Papua New Guinea',       flag:'🇵🇬',dialCode:'675', mobileLength:8),
  _CountryInfo(code:'PY',name:'Paraguay',               flag:'🇵🇾',dialCode:'595', mobileLength:9),
  _CountryInfo(code:'PE',name:'Peru',                   flag:'🇵🇪',dialCode:'51',  mobileLength:9),
  _CountryInfo(code:'PH',name:'Philippines',            flag:'🇵🇭',dialCode:'63',  mobileLength:10),
  _CountryInfo(code:'PL',name:'Poland',                 flag:'🇵🇱',dialCode:'48',  mobileLength:9),
  _CountryInfo(code:'PT',name:'Portugal',               flag:'🇵🇹',dialCode:'351', mobileLength:9),
  _CountryInfo(code:'QA',name:'Qatar',                  flag:'🇶🇦',dialCode:'974', mobileLength:8),
  _CountryInfo(code:'RO',name:'Romania',                flag:'🇷🇴',dialCode:'40',  mobileLength:9),
  _CountryInfo(code:'RU',name:'Russia',                 flag:'🇷🇺',dialCode:'7',   mobileLength:10),
  _CountryInfo(code:'RW',name:'Rwanda',                 flag:'🇷🇼',dialCode:'250', mobileLength:9),
  _CountryInfo(code:'KN',name:'Saint Kitts and Nevis',  flag:'🇰🇳',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'LC',name:'Saint Lucia',            flag:'🇱🇨',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'VC',name:'Saint Vincent',          flag:'🇻🇨',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'WS',name:'Samoa',                  flag:'🇼🇸',dialCode:'685', mobileLength:7),
  _CountryInfo(code:'SM',name:'San Marino',             flag:'🇸🇲',dialCode:'378', mobileLength:8),
  _CountryInfo(code:'ST',name:'Sao Tome and Principe',  flag:'🇸🇹',dialCode:'239', mobileLength:7),
  _CountryInfo(code:'SA',name:'Saudi Arabia',           flag:'🇸🇦',dialCode:'966', mobileLength:9),
  _CountryInfo(code:'SN',name:'Senegal',                flag:'🇸🇳',dialCode:'221', mobileLength:9),
  _CountryInfo(code:'RS',name:'Serbia',                 flag:'🇷🇸',dialCode:'381', mobileLength:9),
  _CountryInfo(code:'SC',name:'Seychelles',             flag:'🇸🇨',dialCode:'248', mobileLength:7),
  _CountryInfo(code:'SL',name:'Sierra Leone',           flag:'🇸🇱',dialCode:'232', mobileLength:8),
  _CountryInfo(code:'SG',name:'Singapore',              flag:'🇸🇬',dialCode:'65',  mobileLength:8),
  _CountryInfo(code:'SK',name:'Slovakia',               flag:'🇸🇰',dialCode:'421', mobileLength:9),
  _CountryInfo(code:'SI',name:'Slovenia',               flag:'🇸🇮',dialCode:'386', mobileLength:8),
  _CountryInfo(code:'SB',name:'Solomon Islands',        flag:'🇸🇧',dialCode:'677', mobileLength:7),
  _CountryInfo(code:'SO',name:'Somalia',                flag:'🇸🇴',dialCode:'252', mobileLength:8),
  _CountryInfo(code:'ZA',name:'South Africa',           flag:'🇿🇦',dialCode:'27',  mobileLength:9),
  _CountryInfo(code:'KR',name:'South Korea',            flag:'🇰🇷',dialCode:'82',  mobileLength:10),
  _CountryInfo(code:'SS',name:'South Sudan',            flag:'🇸🇸',dialCode:'211', mobileLength:9),
  _CountryInfo(code:'ES',name:'Spain',                  flag:'🇪🇸',dialCode:'34',  mobileLength:9),
  _CountryInfo(code:'LK',name:'Sri Lanka',              flag:'🇱🇰',dialCode:'94',  mobileLength:9),
  _CountryInfo(code:'SD',name:'Sudan',                  flag:'🇸🇩',dialCode:'249', mobileLength:9),
  _CountryInfo(code:'SR',name:'Suriname',               flag:'🇸🇷',dialCode:'597', mobileLength:7),
  _CountryInfo(code:'SE',name:'Sweden',                 flag:'🇸🇪',dialCode:'46',  mobileLength:9),
  _CountryInfo(code:'CH',name:'Switzerland',            flag:'🇨🇭',dialCode:'41',  mobileLength:9),
  _CountryInfo(code:'SY',name:'Syria',                  flag:'🇸🇾',dialCode:'963', mobileLength:9),
  _CountryInfo(code:'TW',name:'Taiwan',                 flag:'🇹🇼',dialCode:'886', mobileLength:9),
  _CountryInfo(code:'TJ',name:'Tajikistan',             flag:'🇹🇯',dialCode:'992', mobileLength:9),
  _CountryInfo(code:'TZ',name:'Tanzania',               flag:'🇹🇿',dialCode:'255', mobileLength:9),
  _CountryInfo(code:'TH',name:'Thailand',               flag:'🇹🇭',dialCode:'66',  mobileLength:9),
  _CountryInfo(code:'TL',name:'Timor-Leste',            flag:'🇹🇱',dialCode:'670', mobileLength:8),
  _CountryInfo(code:'TG',name:'Togo',                   flag:'🇹🇬',dialCode:'228', mobileLength:8),
  _CountryInfo(code:'TO',name:'Tonga',                  flag:'🇹🇴',dialCode:'676', mobileLength:7),
  _CountryInfo(code:'TT',name:'Trinidad and Tobago',    flag:'🇹🇹',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'TN',name:'Tunisia',                flag:'🇹🇳',dialCode:'216', mobileLength:8),
  _CountryInfo(code:'TR',name:'Turkey',                 flag:'🇹🇷',dialCode:'90',  mobileLength:10),
  _CountryInfo(code:'TM',name:'Turkmenistan',           flag:'🇹🇲',dialCode:'993', mobileLength:8),
  _CountryInfo(code:'TV',name:'Tuvalu',                 flag:'🇹🇻',dialCode:'688', mobileLength:6),
  _CountryInfo(code:'UG',name:'Uganda',                 flag:'🇺🇬',dialCode:'256', mobileLength:9),
  _CountryInfo(code:'UA',name:'Ukraine',                flag:'🇺🇦',dialCode:'380', mobileLength:9),
  _CountryInfo(code:'AE',name:'United Arab Emirates',   flag:'🇦🇪',dialCode:'971', mobileLength:9),
  _CountryInfo(code:'GB',name:'United Kingdom',         flag:'🇬🇧',dialCode:'44',  mobileLength:10),
  _CountryInfo(code:'US',name:'United States',          flag:'🇺🇸',dialCode:'1',   mobileLength:10),
  _CountryInfo(code:'UY',name:'Uruguay',                flag:'🇺🇾',dialCode:'598', mobileLength:9),
  _CountryInfo(code:'UZ',name:'Uzbekistan',             flag:'🇺🇿',dialCode:'998', mobileLength:9),
  _CountryInfo(code:'VU',name:'Vanuatu',                flag:'🇻🇺',dialCode:'678', mobileLength:7),
  _CountryInfo(code:'VE',name:'Venezuela',              flag:'🇻🇪',dialCode:'58',  mobileLength:10),
  _CountryInfo(code:'VN',name:'Vietnam',                flag:'🇻🇳',dialCode:'84',  mobileLength:9),
  _CountryInfo(code:'YE',name:'Yemen',                  flag:'🇾🇪',dialCode:'967', mobileLength:9),
  _CountryInfo(code:'ZM',name:'Zambia',                 flag:'🇿🇲',dialCode:'260', mobileLength:9),
  _CountryInfo(code:'ZW',name:'Zimbabwe',               flag:'🇿🇼',dialCode:'263', mobileLength:9),
];

_CountryInfo? _findCountry(String codeOrName) {
  if (codeOrName.isEmpty) return null;
  final upper = codeOrName.toUpperCase();
  try {
    return _kCountries.firstWhere(
      (c) => c.code == upper || c.name.toUpperCase() == upper,
    );
  } catch (_) {
    return null;
  }
}

_CountryInfo _mapDbToCountryInfo(Map<String, dynamic> c) {
  final code = (c['countrycode'] ?? c['code'] ?? '').toString().trim().toUpperCase();
  final name = (c['countryname'] ?? c['name'] ?? '').toString().trim();
  final dialCode = (c['callcode'] ?? c['dialCode'] ?? '').toString().replaceAll('+', '').trim();
  
  String flag = '';
  int mobileLen = 10;
  try {
    final match = _kCountries.firstWhere((k) => k.code == code || k.name.toUpperCase() == name.toUpperCase());
    flag = match.flag;
    mobileLen = match.mobileLength;
  } catch (_) {
    if (code.length == 2) {
      try {
        final int first = code.codeUnitAt(0) - 65 + 127462;
        final int second = code.codeUnitAt(1) - 65 + 127462;
        flag = String.fromCharCode(first) + String.fromCharCode(second);
      } catch (_) {}
    }
  }

  return _CountryInfo(
    code: code,
    name: name,
    flag: flag,
    dialCode: dialCode,
    mobileLength: mobileLen,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  Toast
// ═════════════════════════════════════════════════════════════════════════════
class _Toast {
  static OverlayEntry? _current;
  static void show(BuildContext ctx, String msg, {bool isError = false}) {
    _current?.remove(); _current = null;
    final bg     = isError ? _kRL : _kGL;
    final fg     = isError ? _kR  : _kG;
    final border = isError ? _kR.withOpacity(0.4) : _kG.withOpacity(0.4);
    final icon   = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
    final entry  = OverlayEntry(builder: (_) => _ToastWidget(
      message: msg, bg: bg, fg: fg, border: border, icon: icon,
      onDismiss: () { _current?.remove(); _current = null; }));
    _current = entry;
    Overlay.of(ctx).insert(entry);
    Future.delayed(const Duration(seconds: 3), () { entry.remove(); if (_current == entry) _current = null; });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message; final Color bg, fg, border; final IconData icon; final VoidCallback onDismiss;
  const _ToastWidget({required this.message,required this.bg,required this.fg,required this.border,required this.icon,required this.onDismiss});
  @override State<_ToastWidget> createState() => _ToastWidgetState();
}
class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _sl, _fa;
  @override void initState() { super.initState();
    _c = AnimationController(vsync:this,duration:const Duration(milliseconds:320));
    _sl = Tween<double>(begin:-80,end:0).animate(CurvedAnimation(parent:_c,curve:Curves.easeOutCubic));
    _fa = CurvedAnimation(parent:_c,curve:Curves.easeOut); _c.forward(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext ctx) => Positioned(top:24,left:0,right:0,
    child: AnimatedBuilder(animation:_c, builder:(_, child) => Transform.translate(offset:Offset(0,_sl.value),child:Opacity(opacity:_fa.value,child:child)),
      child: Center(child: Container(constraints:const BoxConstraints(maxWidth:480),margin:const EdgeInsets.symmetric(horizontal:24),
        padding:const EdgeInsets.symmetric(horizontal:18,vertical:12),
        decoration:BoxDecoration(color:widget.bg,border:Border.all(color:widget.border),borderRadius:BorderRadius.circular(12),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:16,offset:const Offset(0,4))]),
        child: Row(mainAxisSize:MainAxisSize.min,children:[
          Icon(widget.icon,size:18,color:widget.fg), const SizedBox(width:10),
          Flexible(child:Text(widget.message,style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:widget.fg,decoration:TextDecoration.none,decorationColor:Colors.transparent))),
          const SizedBox(width:10),
          GestureDetector(onTap:widget.onDismiss,child:Icon(Icons.close_rounded,size:16,color:widget.fg)),
        ])))));
}

// ═════════════════════════════════════════════════════════════════════════════
//  Search Box
// ═════════════════════════════════════════════════════════════════════════════
class _SearchBox extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.onChanged});
  @override State<_SearchBox> createState() => _SearchBoxState();
}
class _SearchBoxState extends State<_SearchBox> {
  final FocusNode _f = FocusNode(); bool _focused = false;
  @override void initState() { super.initState(); _f.addListener(()=>setState(()=>_focused=_f.hasFocus)); }
  @override void dispose() { _f.dispose(); super.dispose(); }
  @override Widget build(BuildContext ctx) => AnimatedContainer(
    duration:const Duration(milliseconds:150), height:36, width:200,
    decoration:BoxDecoration(color:Colors.white,border:Border.all(color:_focused?_kP:_kBorder,width:_focused?2:1.5),
      borderRadius:BorderRadius.circular(10),
      boxShadow:_focused?[BoxShadow(color:_kP.withOpacity(0.12),blurRadius:6,offset:const Offset(0,2))]:const []),
    child:TextField(focusNode:_f,onChanged:widget.onChanged,style:const TextStyle(fontSize:13,color:_kText),
      decoration:InputDecoration(hintText:'Search users',
        hintStyle:TextStyle(fontSize:12,color:_focused?const Color(0xFFB0BEC5):const Color(0xFFCBD5E1)),
        prefixIcon:Icon(Icons.search_rounded,size:16,color:_focused?_kP:const Color(0xFF94A3B8)),
        border:InputBorder.none,enabledBorder:InputBorder.none,focusedBorder:InputBorder.none,
        contentPadding:const EdgeInsets.symmetric(vertical:10),isDense:true)));
}

// ═════════════════════════════════════════════════════════════════════════════
//  Org Filter Button
// ═════════════════════════════════════════════════════════════════════════════
class _OrgFilterButton extends StatefulWidget {
  final String? selectedOrgCode;
  final List<Map<String, dynamic>> organizations;
  final ValueChanged<String?> onChanged;

  const _OrgFilterButton({
    required this.selectedOrgCode,
    required this.organizations,
    required this.onChanged,
  });

  @override
  State<_OrgFilterButton> createState() => _OrgFilterButtonState();
}

class _OrgFilterButtonState extends State<_OrgFilterButton> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _rm();
    _sc.dispose();
    super.dispose();
  }

  void _rm() {
    _ov?.remove();
    _ov = null;
  }

  String _getDispLabel() {
    if (widget.selectedOrgCode == null || widget.selectedOrgCode!.isEmpty) {
      return 'All Organizations';
    }
    final code = widget.selectedOrgCode!;
    final o = widget.organizations.firstWhere(
      (e) => e['orgCode']?['orgcode'].toString() == code,
      orElse: () => <String, dynamic>{},
    );
    if (o.isEmpty) return code;
    final n = (o['orgName'] ?? o['name'] ?? '').toString();
    return n.isNotEmpty ? '$code - $n' : code;
  }

  void _open() {
    _rm();
    _sc.clear();
    _q = '';
    final rb = _key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov);
    final sz = rb.size;
    const dropW = 290.0;
    final left = pos.dx + sz.width - dropW;
    _ov = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _rm,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: pos.dy + sz.height + 4,
                width: dropW,
                child: StatefulBuilder(
                  builder: (c2, ss) => Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _sc,
                              autofocus: true,
                              onChanged: (v) => ss(() => _q = v),
                              style: const TextStyle(fontSize: 13, color: _kText),
                              decoration: InputDecoration(
                                hintText: 'Search organization...',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: _kSurface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kP, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: _kBorder),
                          Flexible(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              children: [
                                _item(c2, null, 'All Organizations', '', ss),
                                ...widget.organizations.where((o) {
 final code = (o['orgCode'] ?? o['orgcode'])?.toString() ?? '';                                  final nm = (o['orgName'] ?? o['name'] ?? '').toString().toLowerCase();
                                  return _q.isEmpty || code.contains(_q.toLowerCase()) || nm.contains(_q.toLowerCase());
                                }).map((o) {
 final code = (o['orgCode'] ?? o['orgcode'])?.toString() ?? '';                                  final nm = (o['orgName'] ?? o['name'] ?? '').toString();
                                  return _item(c2, code, nm, code, ss);
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_ov!);
  }

  Widget _item(BuildContext c, String? code, String name, String dispCode, StateSetter ss) {
    final isSel = (widget.selectedOrgCode ?? '') == (code ?? '');
    return InkWell(
      onTap: () {
        widget.onChanged(code);
        _rm();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: isSel ? _kPL : Colors.transparent,
        child: Row(
          children: [
            if (dispCode.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: _kPL, borderRadius: BorderRadius.circular(4)),
                child: Text(dispCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP)),
              ),
            Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: _kText, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
            if (isSel) const Icon(Icons.check_rounded, size: 14, color: _kP),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final has = widget.selectedOrgCode != null && widget.selectedOrgCode!.isNotEmpty;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _open,
        child: Container(
          key: _key,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: has ? _kPL : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: has ? _kP : _kBorder, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business_rounded, size: 15, color: has ? _kP : _kMuted),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  _getDispLabel(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: has ? _kP : _kMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (has) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    widget.onChanged(null);
                  },
                  child: Icon(Icons.close_rounded, size: 14, color: _kP),
                ),
              ] else ...[
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchFilterButton extends StatefulWidget {
  final String? selectedBranchCode;
  final String? selectedOrgCode;
  final List<Branch> branches;
  final ValueChanged<String?> onChanged;

  const _BranchFilterButton({
    required this.selectedBranchCode,
    required this.selectedOrgCode,
    required this.branches,
    required this.onChanged,
  });

  @override
  State<_BranchFilterButton> createState() => _BranchFilterButtonState();
}

class _BranchFilterButtonState extends State<_BranchFilterButton> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _rm();
    _sc.dispose();
    super.dispose();
  }

  void _rm() {
    _ov?.remove();
    _ov = null;
  }

  String _getDispLabel() {
    if (widget.selectedBranchCode == null || widget.selectedBranchCode!.isEmpty) {
      return 'All Branches';
    }
    final code = widget.selectedBranchCode!;
    final b = widget.branches.firstWhere(
      (e) => e.branchCode.toString() == code,
      orElse: () => Branch(orgCode: 0, branchCode: 0, branchName: ''),
    );
    return b.branchName.isNotEmpty ? '$code - ${b.branchName}' : code;
  }

  void _open() {
    _rm();
    _sc.clear();
    _q = '';
    final rb = _key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov);
    final sz = rb.size;
    const dropW = 290.0;
    final left = pos.dx + sz.width - dropW;
    _ov = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _rm,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: pos.dy + sz.height + 4,
                width: dropW,
                child: StatefulBuilder(
                  builder: (c2, ss) {
                    final filteredBranches = widget.selectedOrgCode != null
                        ? widget.branches.where((b) => b.orgCode.toString() == widget.selectedOrgCode).toList()
                        : widget.branches;

                    return Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 260),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                controller: _sc,
                                autofocus: true,
                                onChanged: (v) => ss(() => _q = v),
                                style: const TextStyle(fontSize: 13, color: _kText),
                                decoration: InputDecoration(
                                  hintText: 'Search branch...',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: _kSurface,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kP, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: _kBorder),
                            Flexible(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                shrinkWrap: true,
                                children: [
                                  _item(c2, null, 'All Branches', '', ss),
                                  ...filteredBranches.where((b) {
                                    final code = b.branchCode.toString();
                                    final nm = b.branchName.toLowerCase();
                                    return _q.isEmpty || code.contains(_q.toLowerCase()) || nm.contains(_q.toLowerCase());
                                  }).map((b) {
                                    return _item(c2, b.branchCode.toString(), b.branchName, b.branchCode.toString(), ss);
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_ov!);
  }

  Widget _item(BuildContext c, String? code, String name, String dispCode, StateSetter ss) {
    final isSel = (widget.selectedBranchCode ?? '') == (code ?? '');
    return InkWell(
      onTap: () {
        widget.onChanged(code);
        _rm();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: isSel ? _kPL : Colors.transparent,
        child: Row(
          children: [
            if (dispCode.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: _kPL, borderRadius: BorderRadius.circular(4)),
                child: Text(dispCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP)),
              ),
            Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: _kText, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
            if (isSel) const Icon(Icons.check_rounded, size: 14, color: _kP),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final has = widget.selectedBranchCode != null && widget.selectedBranchCode!.isNotEmpty;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _open,
        child: Container(
          key: _key,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: has ? _kPL : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: has ? _kP : _kBorder, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_rounded, size: 15, color: has ? _kP : _kMuted),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  _getDispLabel(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: has ? _kP : _kMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (has) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    widget.onChanged(null);
                  },
                  child: Icon(Icons.close_rounded, size: 14, color: _kP),
                ),
              ] else ...[
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Floating Label Text Field
// ═════════════════════════════════════════════════════════════════════════════
class _FloatingLabelField extends StatefulWidget {
  final String label; final TextEditingController controller; final IconData icon;
  final String hint; final bool readOnly; final bool isRequired; final String? errorText;
  final bool isDatePicker; final DateTime? maxDate; final DateTime? minDate; final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool showLock;
  final String? subtext;

  const _FloatingLabelField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint='',
    this.readOnly=false,
    this.isRequired=false,
    this.errorText,
    this.isDatePicker=false,
    this.maxDate,
    this.minDate,
    this.focusNode,
    this.onChanged,
    this.maxLength,
    this.inputFormatters,
    this.showLock = false,
    this.subtext,
  });

  @override State<_FloatingLabelField> createState() => _FloatingLabelFieldState();
}

class _FloatingLabelFieldState extends State<_FloatingLabelField> with SingleTickerProviderStateMixin {
  late final FocusNode _fn;
  bool _focused = false;
  late AnimationController _ac;
  late Animation<double> _top, _sz;

  bool get _hasVal => widget.controller.text.isNotEmpty;
  bool get _floated => _focused || _hasVal || widget.errorText != null;

  @override void initState() {
    super.initState();
    _fn = widget.focusNode ?? FocusNode();
    _ac = AnimationController(vsync:this,duration:const Duration(milliseconds:180),value:_floated?1:0);
    _top = Tween<double>(begin:13,end:-8).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    _sz  = Tween<double>(begin:13,end:10.5).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    _fn.addListener((){ setState(()=>_focused=_fn.hasFocus); _floated?_ac.forward():_ac.reverse(); });
    widget.controller.addListener((){
      if (mounted) {
        setState((){});
        _floated?_ac.forward():_ac.reverse();
      }
      widget.onChanged?.call(widget.controller.text);
    });
  }

  @override void didUpdateWidget(_FloatingLabelField o) {
    super.didUpdateWidget(o);
    _floated?_ac.forward():_ac.reverse();
  }

  @override void dispose() {
    if(widget.focusNode==null)_fn.dispose();
    _ac.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (widget.readOnly) return;
    final maxD = widget.maxDate ?? DateTime(2100);
    final minD = widget.minDate ?? DateTime(1900);
    DateTime ini = DateTime.now();
    if(ini.isAfter(maxD)) ini=maxD;
    if(ini.isBefore(minD)) ini=minD;
    try {
      final p = widget.controller.text.split('-');
      if(p.length==3){
        const mo={'Jan':1,'January':1,'Feb':2,'February':2,'Mar':3,'March':3,'Apr':4,'April':4,'May':5,'Jun':6,'June':6,'Jul':7,'July':7,'Aug':8,'August':8,'Sep':9,'September':9,'Oct':10,'October':10,'Nov':11,'November':11,'Dec':12,'December':12};
        final parsed=DateTime(int.parse(p[2]),mo[p[1]]??1,int.parse(p[0]));
        if(!parsed.isAfter(maxD) && !parsed.isBefore(minD)) ini=parsed;
      }
    } catch(_){}
    final pk = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: CustomCalendarDialog(
          initialDate: ini,
          firstDate: minD,
          lastDate: maxD,
          title: 'Select ${widget.label}',
        ),
      ),
    );
    if(pk!=null){
      if (pk == DateTime(1900, 1, 1)) {
        widget.controller.clear();
      } else {
        const ms=['January','February','March','April','May','June','July','August','September','October','November','December'];
        widget.controller.text='${pk.day.toString().padLeft(2,'0')}-${ms[pk.month-1]}-${pk.year}';
      }
      _ac.forward();
    }
  }

  @override Widget build(BuildContext ctx) {
    final err = widget.errorText!=null;
    final bc  = err?_kR:_kP;

    final Widget textField = TextField(
      controller: widget.controller,
      focusNode: _fn,
      readOnly: widget.isDatePicker || widget.readOnly,
      showCursor: widget.isDatePicker ? false : null,
      enableInteractiveSelection: !widget.isDatePicker,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      style: const TextStyle(fontSize:13,fontWeight:FontWeight.w500,color:_kText),
      decoration: InputDecoration(
        hintText: _floated ? widget.hint : '',
        hintStyle: const TextStyle(fontSize:12.5,color:Color(0xFFCBD5E1)),
        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.fromLTRB(36,14,12,14), isDense: true,
        suffixIcon: (widget.showLock && widget.readOnly) ? Icon(Icons.lock_outline_rounded, size: 16, color: _kMuted.withOpacity(0.5)) : null,
      ));

    Widget field = Container(
      height: 44,
      decoration: BoxDecoration(
        color: widget.readOnly ? _kSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bc, width: 1.5)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.5),
        child: widget.isDatePicker && !widget.readOnly
            ? AbsorbPointer(child: textField)
            : textField,
      ));

    if (widget.isDatePicker && !widget.readOnly) {
      field = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _pick,
          behavior: HitTestBehavior.opaque,
          child: field,
        ),
      );
    }

    return Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Stack(clipBehavior:Clip.none,children:[
        field,
        Positioned(left:10,top:0,bottom:0,
          child:Align(alignment:Alignment.centerLeft,
            child:Icon(widget.isDatePicker?Icons.calendar_month_rounded:widget.icon,size:14,color:bc))),
        AnimatedBuilder(animation:_ac,builder:(_, __)=>Positioned(top:_top.value,left:28,
          child:GestureDetector(
            onTap: widget.isDatePicker && !widget.readOnly
                ? _pick
                : (!widget.readOnly ? ()=>_fn.requestFocus() : null),
            child:Container(color:Colors.white,padding:const EdgeInsets.symmetric(horizontal:4),
              child:Text.rich(
                TextSpan(
                  text: widget.label,
                  children: [
                    if (widget.isRequired)
                      const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                  ],
                ),
                style:TextStyle(fontSize:_sz.value,fontWeight:FontWeight.w600,
                  color:bc,letterSpacing:0.2,decoration:TextDecoration.none)))))),
      ]),
      if(widget.subtext!=null && widget.subtext!.isNotEmpty)
        Padding(padding:const EdgeInsets.only(top:5,left:2),
          child:Text(widget.subtext!,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:_kP,height:1.2))),
      if(err) Padding(padding:const EdgeInsets.only(top:6,left:2),
        child:Text(widget.errorText!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:_kR,height:1.2))),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Simple Dropdown Field
// ═════════════════════════════════════════════════════════════════════════════
class _SimpleDropdownField extends StatefulWidget {
  final String label; final TextEditingController controller; final IconData icon;
  final List<String> items; final String hint; final bool isRequired; final String? errorText;
  final ValueChanged<String>? onChanged;
  const _SimpleDropdownField({required this.label,required this.controller,required this.icon,
    required this.items,this.hint='',this.isRequired=false,this.errorText,this.onChanged});
  @override State<_SimpleDropdownField> createState() => _SimpleDropdownFieldState();
}
class _SimpleDropdownFieldState extends State<_SimpleDropdownField> with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey(); OverlayEntry? _ov;
  late AnimationController _ac; late Animation<double> _top,_sz;
  bool _isOpen = false;
  FocusNode? _popupFocusNode;

  bool get _hasVal => widget.controller.text.isNotEmpty;
  bool get _floated => _hasVal || _isOpen || widget.errorText!=null;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync:this,duration:const Duration(milliseconds:180),value:_floated?1:0);
    _top = Tween<double>(begin:13,end:-8).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    _sz  = Tween<double>(begin:13,end:10.5).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    widget.controller.addListener((){ setState((){}); _floated?_ac.forward():_ac.reverse(); });
  }
  @override void didUpdateWidget(_SimpleDropdownField o) { super.didUpdateWidget(o); _floated?_ac.forward():_ac.reverse(); }
  @override void dispose() { _rm(); _ac.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov=null; _popupFocusNode?.dispose(); _popupFocusNode=null; setState(()=>_isOpen=false); _floated?_ac.forward():_ac.reverse(); }

  void _open() {
    _rm();
    _popupFocusNode = FocusNode()..requestFocus();
    setState(()=>_isOpen=true); _ac.forward();
    final rb=_key.currentContext?.findRenderObject() as RenderBox?; if(rb==null)return;
    final ov=Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos=rb.localToGlobal(Offset.zero,ancestor:ov); final sz=rb.size;
    int hlIdx = widget.items.indexOf(widget.controller.text);
    if (hlIdx < 0) hlIdx = 0;

    _ov = OverlayEntry(builder:(ctx)=>GestureDetector(behavior:HitTestBehavior.translucent,onTap:_rm,
      child:Material(color:Colors.transparent,child:Stack(children:[
        Positioned(left:pos.dx,top:pos.dy+sz.height+4,width:sz.width,
          child:StatefulBuilder(builder:(c2, ss) {
            void selectHl() {
              if (widget.items.isNotEmpty && hlIdx < widget.items.length) {
                final item = widget.items[hlIdx];
                widget.controller.text = item;
                setState(() {});
                _rm();
                widget.onChanged?.call(item);
              }
            }

            return KeyboardListener(
              focusNode: _popupFocusNode!,
              autofocus: true,
              onKeyEvent: (event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.arrowDown) {
                  ss(() => hlIdx = (hlIdx + 1).clamp(0, widget.items.length - 1));
                } else if (key == LogicalKeyboardKey.arrowUp) {
                  ss(() => hlIdx = (hlIdx - 1).clamp(0, widget.items.length - 1));
                } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                  selectHl();
                } else if (key == LogicalKeyboardKey.escape) {
                  _rm();
                }
              },
              child: Material(elevation:8,borderRadius:BorderRadius.circular(14),
                child:Container(
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:_kBorder)),
                  child:Column(mainAxisSize:MainAxisSize.min,children:widget.items.asMap().entries.map((entry){
                    final idx = entry.key; final item = entry.value;
                    final isSel=widget.controller.text==item;
                    final isHl = hlIdx == idx;
                    final isAct=item=='Active'; final isIna=item=='Inactive';
                    Color? dot=isAct?_kG:(isIna?_kR:null);
                    return InkWell(onTap:(){
                      widget.controller.text=item;
                      setState((){});
                      _rm();
                      widget.onChanged?.call(item);
                    },
                      child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
                        color:isHl ? _kPL.withOpacity(0.8) : (isSel?_kPL:Colors.transparent),
                        child:Row(children:[
                          if(dot!=null) Container(width:8,height:8,margin:const EdgeInsets.only(right:8),decoration:BoxDecoration(color:dot,shape:BoxShape.circle)),
                          Expanded(child:Text(item,style:TextStyle(fontSize:13,color:dot??_kText,fontWeight:isSel?FontWeight.w600:FontWeight.w400))),
                          if(isSel) const Icon(Icons.check_rounded,size:14,color:_kP),
                        ])));
                  }).toList()))),
            );
          })),
      ]))));
    Overlay.of(context).insert(_ov!);
  }

  @override Widget build(BuildContext ctx) {
    final err=widget.errorText!=null; final bc=err?_kR:_kP;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Stack(clipBehavior:Clip.none,children:[
        GestureDetector(onTap:_open,child:Container(key:_key,height:44,
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),border:Border.all(color:bc,width:1.5)),
          child:ClipRRect(borderRadius:BorderRadius.circular(10.5),
            child:Padding(padding:const EdgeInsets.fromLTRB(40,12,36,12),
              child:Row(children:[
                Expanded(child:Text(
                  widget.controller.text.isEmpty ? (_floated ? widget.hint : '') : widget.controller.text,
                  style:TextStyle(fontSize:13,fontWeight:FontWeight.w500,
                    color:widget.controller.text.isEmpty?_kMuted:_kText),
                  overflow:TextOverflow.ellipsis)),
                const Icon(Icons.arrow_drop_down,size:20,color:_kP),
              ]))))),
        Positioned(left:10,top:0,bottom:0,child:Align(alignment:Alignment.centerLeft,child:Icon(widget.icon,size:14,color:bc))),
        AnimatedBuilder(animation:_ac,builder:(_,__)=>Positioned(top:_top.value,left:28,
          child:GestureDetector(onTap:_open,
            child:Container(color:Colors.white,padding:const EdgeInsets.symmetric(horizontal:4),
              child:Text.rich(TextSpan(text: widget.label, children: [if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]),
                style:TextStyle(fontSize:_sz.value,fontWeight:FontWeight.w600,color:bc,
                  letterSpacing:0.2,decoration:TextDecoration.none)))))),
      ]),
      if(err) Padding(padding:const EdgeInsets.only(top:6,left:2),
        child:Text(widget.errorText!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:_kR,height:1.2))),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Org Dropdown Field
// ═════════════════════════════════════════════════════════════════════════════
class _OrgDropdownField extends StatefulWidget {
  final String label; final TextEditingController controller;
  final List<Map<String,dynamic>> organizations;
  final bool readOnly; final bool isRequired; final ValueChanged<String> onChanged;
  final String? errorText;
  const _OrgDropdownField({required this.label,required this.controller,required this.organizations,
    this.readOnly=false,this.isRequired=false,required this.onChanged,this.errorText});
  @override State<_OrgDropdownField> createState() => _OrgDropdownFieldState();
}
class _OrgDropdownFieldState extends State<_OrgDropdownField> with SingleTickerProviderStateMixin {
  final GlobalKey _key=GlobalKey(); OverlayEntry? _ov;
  final TextEditingController _sc=TextEditingController();
  late AnimationController _ac; late Animation<double> _top,_sz;
  bool _isOpen=false;
  FocusNode? _popupFocusNode;

  bool get _hasVal => widget.controller.text.isNotEmpty;
  bool get _floated => _hasVal || _isOpen || widget.errorText!=null;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync:this,duration:const Duration(milliseconds:180),value:_floated?1:0);
    _top = Tween<double>(begin:13,end:-8).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    _sz  = Tween<double>(begin:13,end:10.5).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    widget.controller.addListener((){ setState((){}); _floated?_ac.forward():_ac.reverse(); });
  }
  @override void didUpdateWidget(_OrgDropdownField o) { super.didUpdateWidget(o); _floated?_ac.forward():_ac.reverse(); }
  @override void dispose() { _rm(); _sc.dispose(); _ac.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov=null; _popupFocusNode?.dispose(); _popupFocusNode=null; setState(()=>_isOpen=false); _floated?_ac.forward():_ac.reverse(); }

  void _open() {
    if(widget.readOnly)return; _rm(); _sc.clear();
    _popupFocusNode = FocusNode();
    setState(()=>_isOpen=true); _ac.forward();
    final rb=_key.currentContext?.findRenderObject() as RenderBox?; if(rb==null)return;
    final ov=Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos=rb.localToGlobal(Offset.zero,ancestor:ov); final sz=rb.size;
    int hlIdx = 0;
    final ScrollController scrollCtrl = ScrollController();

    void scrollTo(int idx) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(idx * 38.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      }
    }

    _ov=OverlayEntry(builder:(ctx)=>GestureDetector(behavior:HitTestBehavior.translucent,onTap:_rm,
      child:Material(color:Colors.transparent,child:Stack(children:[
        Positioned(left:pos.dx,top:pos.dy+sz.height+4,width:sz.width.clamp(240.0,360.0),
          child:StatefulBuilder(builder:(c2,ss){
            final filtered = widget.organizations.where((o){
              final code=o['orgCode']??o['orgcode']?.toString()??''; final nm=(o['orgName']??o['name']??'').toString().toLowerCase();
              final q=_sc.text.toLowerCase(); return q.isEmpty||code.contains(q)||nm.contains(q);
            }).toList();

            if (hlIdx >= filtered.length) hlIdx = filtered.isNotEmpty ? filtered.length - 1 : 0;
            if (hlIdx < 0) hlIdx = 0;

            void selectHl() {
              if (filtered.isNotEmpty && hlIdx < filtered.length) {
                final o = filtered[hlIdx];
                final code = o['orgCode']??o['orgcode']?.toString() ?? '';
                final nm = (o['orgName'] ?? o['name'] ?? '').toString();
                widget.onChanged('$code - $nm');
                _rm();
              }
            }

            return KeyboardListener(
              focusNode: _popupFocusNode!,
              autofocus: true,
              onKeyEvent: (event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.arrowDown) {
                  ss(() => hlIdx = (hlIdx + 1).clamp(0, filtered.length - 1));
                  scrollTo(hlIdx);
                } else if (key == LogicalKeyboardKey.arrowUp) {
                  ss(() => hlIdx = (hlIdx - 1).clamp(0, filtered.length - 1));
                  scrollTo(hlIdx);
                } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                  selectHl();
                } else if (key == LogicalKeyboardKey.escape) {
                  _rm();
                }
              },
              child: Material(elevation:8,borderRadius:BorderRadius.circular(14),
                child:Container(constraints:const BoxConstraints(maxHeight:260),
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:_kBorder)),
                  child:Column(mainAxisSize:MainAxisSize.min,children:[
                    Padding(padding:const EdgeInsets.all(8),child:TextField(controller:_sc,autofocus:true,
                      onChanged:(_)=>ss((){ hlIdx = 0; }),
                      onSubmitted:(_) => selectHl(),
                      style:const TextStyle(fontSize:13,color:_kText),
                      decoration:InputDecoration(hintText:'Search organization...',
                        hintStyle:const TextStyle(fontSize:12,color:Color(0xFFCBD5E1)),
                        prefixIcon:const Icon(Icons.search_rounded,size:16,color:Color(0xFF94A3B8)),
                        filled:true,fillColor:_kSurface,
                        border:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kBorder)),
                        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kBorder)),
                        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kP,width:1.5)),
                        contentPadding:const EdgeInsets.symmetric(vertical:8),isDense:true))),
                    const Divider(height:1,color:_kBorder),
                    Flexible(child:ListView.builder(
                      controller: scrollCtrl,
                      padding:const EdgeInsets.symmetric(vertical:4),
                      shrinkWrap:true,
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final o = filtered[idx];
                        final code=o['orgCode']??o['orgcode']?.toString()??''; final nm=(o['orgName']??o['name']??'').toString();
                        final lbl='$code - $nm'; final isSel=widget.controller.text.startsWith(code);
                        final isHl = hlIdx == idx;
                        return InkWell(onTap:(){ widget.onChanged(lbl); _rm(); },
                          child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),
                            color:isHl ? _kPL.withOpacity(0.8) : (isSel?_kPL:Colors.transparent),
                            child:Row(children:[
                              Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),margin:const EdgeInsets.only(right:8),
                                decoration:BoxDecoration(color:_kPL,borderRadius:BorderRadius.circular(4)),
                                child:Text(code,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:_kP))),
                              Expanded(child:Text(nm,style:TextStyle(fontSize:13,color:_kText,fontWeight:isSel?FontWeight.w600:FontWeight.w400),overflow:TextOverflow.ellipsis)),
                              if(isSel) const Icon(Icons.check_rounded,size:14,color:_kP),
                            ])));
                      },
                    )),
                  ]))),
            );
          })),
      ]))));
    Overlay.of(context).insert(_ov!);
  }

  @override Widget build(BuildContext ctx) {
    final err=widget.errorText!=null; final bc=err?_kR:_kP;
    final textVal = widget.controller.text.trim();
    final codePart = textVal.contains(' - ') ? textVal.split(' - ').first.trim() : textVal;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Stack(clipBehavior:Clip.none,children:[
        GestureDetector(onTap:_open,child:Container(key:_key,height:44,
          decoration:BoxDecoration(color:widget.readOnly?_kSurface:Colors.white,
            borderRadius:BorderRadius.circular(12),border:Border.all(color:bc,width:1.5)),
          child:ClipRRect(borderRadius:BorderRadius.circular(10.5),
            child:Padding(padding:const EdgeInsets.fromLTRB(40,12,36,12),
              child:Row(children:[
                Expanded(child:Text(
                  widget.controller.text.isEmpty ? (_floated ? 'Search organization...' : '') : codePart,
                  style:TextStyle(fontSize:13,fontWeight:FontWeight.w500,color:widget.controller.text.isEmpty?_kMuted:_kText),
                  overflow:TextOverflow.ellipsis)),
                widget.readOnly?const Icon(Icons.lock_outline,size:14,color:_kMuted):const Icon(Icons.arrow_drop_down,size:20,color:_kP),
              ]))))),
        Positioned(left:10,top:0,bottom:0,child:Align(alignment:Alignment.centerLeft,child:Icon(Icons.apartment_rounded,size:14,color:bc))),
        AnimatedBuilder(animation:_ac,builder:(_,__)=>Positioned(top:_top.value,left:28,
          child:GestureDetector(onTap:_open,
            child:Container(color:Colors.white,padding:const EdgeInsets.symmetric(horizontal:4),
              child:Text.rich(TextSpan(text: widget.label, children: [if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]),
                style:TextStyle(fontSize:_sz.value,fontWeight:FontWeight.w600,color:bc,
                  letterSpacing:0.2,decoration:TextDecoration.none)))))),
      ]),
      Builder(
        builder: (context) {
          if (widget.controller.text.isNotEmpty) {
            final s = widget.controller.text.trim();
            final code = s.contains(' - ') ? s.split(' - ').first.trim() : s;
            final match = widget.organizations.where((o) => (o['orgCode']??o['orgcode']?.toString() ?? '') == code).toList();
            if (match.isNotEmpty) {
              final nm = match.first['orgName'] ?? match.first['name']?.toString() ?? '';
              if (nm.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Text(nm, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kP, height: 1.2)),
                );
              }
            }
          }
          return const SizedBox.shrink();
        },
      ),
      if(err) Padding(padding:const EdgeInsets.only(top:6,left:2),
        child:Text(widget.errorText!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:_kR,height:1.2))),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Branch Dropdown Field
// ═════════════════════════════════════════════════════════════════════════════
class _BranchDropdownField extends StatefulWidget {
  final String label; final TextEditingController controller; final List<Branch> branches;
  final bool readOnly; final bool isRequired; final ValueChanged<String> onChanged;
  final String? errorText; final int? selectedOrgCode;
  const _BranchDropdownField({required this.label,required this.controller,required this.branches,
    this.readOnly=false,this.isRequired=false,required this.onChanged,this.errorText,this.selectedOrgCode});
  @override State<_BranchDropdownField> createState() => _BranchDropdownFieldState();
}
class _BranchDropdownFieldState extends State<_BranchDropdownField> with SingleTickerProviderStateMixin {
  final GlobalKey _key=GlobalKey(); OverlayEntry? _ov;
  final TextEditingController _sc=TextEditingController();
  late AnimationController _ac; late Animation<double> _top,_sz;
  bool _isOpen=false;
  FocusNode? _popupFocusNode;

  bool get _hasVal => widget.controller.text.isNotEmpty;
  bool get _floated => _hasVal || _isOpen || widget.errorText!=null;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync:this,duration:const Duration(milliseconds:180),value:_floated?1:0);
    _top = Tween<double>(begin:13,end:-8).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    _sz  = Tween<double>(begin:13,end:10.5).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    widget.controller.addListener((){ setState((){}); _floated?_ac.forward():_ac.reverse(); });
  }
  @override void didUpdateWidget(_BranchDropdownField o) { super.didUpdateWidget(o); _floated?_ac.forward():_ac.reverse(); }
  @override void dispose() { _rm(); _sc.dispose(); _ac.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov=null; _popupFocusNode?.dispose(); _popupFocusNode=null; setState(()=>_isOpen=false); _floated?_ac.forward():_ac.reverse(); }

  void _open() {
    if(widget.readOnly)return; _rm(); _sc.clear();
    _popupFocusNode = FocusNode();
    setState(()=>_isOpen=true); _ac.forward();
    final rb=_key.currentContext?.findRenderObject() as RenderBox?; if(rb==null)return;
    final ov=Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos=rb.localToGlobal(Offset.zero,ancestor:ov); final sz=rb.size;
    int hlIdx = 0;
    final ScrollController scrollCtrl = ScrollController();

    void scrollTo(int idx) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(idx * 38.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      }
    }

    _ov=OverlayEntry(builder:(ctx)=>GestureDetector(behavior:HitTestBehavior.translucent,onTap:_rm,
      child:Material(color:Colors.transparent,child:Stack(children:[
        Positioned(left:pos.dx,top:pos.dy+sz.height+4,width:sz.width.clamp(240.0,360.0),
          child:StatefulBuilder(builder:(c2,ss){
            final filteredBranches = widget.selectedOrgCode != null ? widget.branches.where((b) => b.orgCode == widget.selectedOrgCode).toList() : widget.branches;
            final filtered = filteredBranches.where((b){
              final code=b.branchCode.toString(); final nm=b.branchName.toLowerCase();
              final q=_sc.text.toLowerCase(); return q.isEmpty||code.contains(q)||nm.contains(q);
            }).toList();

            if (hlIdx >= filtered.length) hlIdx = filtered.isNotEmpty ? filtered.length - 1 : 0;
            if (hlIdx < 0) hlIdx = 0;

            void selectHl() {
              if (filtered.isNotEmpty && hlIdx < filtered.length) {
                final b = filtered[hlIdx];
                final code = b.branchCode.toString();
                final nm = b.branchName;
                widget.onChanged('$code - $nm');
                _rm();
              }
            }

            return KeyboardListener(
              focusNode: _popupFocusNode!,
              autofocus: true,
              onKeyEvent: (event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.arrowDown) {
                  ss(() => hlIdx = (hlIdx + 1).clamp(0, filtered.length - 1));
                  scrollTo(hlIdx);
                } else if (key == LogicalKeyboardKey.arrowUp) {
                  ss(() => hlIdx = (hlIdx - 1).clamp(0, filtered.length - 1));
                  scrollTo(hlIdx);
                } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                  selectHl();
                } else if (key == LogicalKeyboardKey.escape) {
                  _rm();
                }
              },
              child: Material(elevation:8,borderRadius:BorderRadius.circular(14),
                child:Container(constraints:const BoxConstraints(maxHeight:260),
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:_kBorder)),
                  child:Column(mainAxisSize:MainAxisSize.min,children:[
                    Padding(padding:const EdgeInsets.all(8),child:TextField(controller:_sc,autofocus:true,
                      onChanged:(_)=>ss((){ hlIdx = 0; }),
                      onSubmitted:(_) => selectHl(),
                      style:const TextStyle(fontSize:13,color:_kText),
                      decoration:InputDecoration(hintText:'Search branch...',
                        hintStyle:const TextStyle(fontSize:12,color:Color(0xFFCBD5E1)),
                        prefixIcon:const Icon(Icons.search_rounded,size:16,color:Color(0xFF94A3B8)),
                        filled:true,fillColor:_kSurface,
                        border:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kBorder)),
                        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kBorder)),
                        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kP,width:1.5)),
                        contentPadding:const EdgeInsets.symmetric(vertical:8),isDense:true))),
                    const Divider(height:1,color:_kBorder),
                    Flexible(child:ListView.builder(
                      controller: scrollCtrl,
                      padding:const EdgeInsets.symmetric(vertical:4),
                      shrinkWrap:true,
                      itemCount: filtered.length,
                      itemBuilder:(context, idx) {
                        final b = filtered[idx];
                        final code=b.branchCode.toString(); final nm=b.branchName;
                        final lbl='$code - $nm'; final isSel=widget.controller.text.startsWith(code);
                        final isHl = hlIdx == idx;
                        return InkWell(onTap:(){ widget.onChanged(lbl); _rm(); },
                          child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),
                            color:isHl ? _kPL.withOpacity(0.8) : (isSel?_kPL:Colors.transparent),
                            child:Row(children:[
                              Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),margin:const EdgeInsets.only(right:8),
                                decoration:BoxDecoration(color:_kPL,borderRadius:BorderRadius.circular(4)),
                                child:Text(code,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:_kP))),
                              Expanded(child:Text(nm,style:TextStyle(fontSize:13,color:_kText,fontWeight:isSel?FontWeight.w600:FontWeight.w400),overflow:TextOverflow.ellipsis)),
                              if(isSel) const Icon(Icons.check_rounded,size:14,color:_kP),
                            ])));
                      },
                    )),
                  ]))),
            );
          })),
      ]))));
    Overlay.of(context).insert(_ov!);
  }

  @override Widget build(BuildContext ctx) {
    final err=widget.errorText!=null; final bc=err?_kR:_kP;
    final textVal = widget.controller.text.trim();
    final codePart = textVal.contains(' - ') ? textVal.split(' - ').first.trim() : textVal;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Stack(clipBehavior:Clip.none,children:[
        GestureDetector(onTap:_open,child:Container(key:_key,height:44,
          decoration:BoxDecoration(color:widget.readOnly?_kSurface:Colors.white,
            borderRadius:BorderRadius.circular(12),border:Border.all(color:bc,width:1.5)),
          child:ClipRRect(borderRadius:BorderRadius.circular(10.5),
            child:Padding(padding:const EdgeInsets.fromLTRB(40,12,36,12),
              child:Row(children:[
                Expanded(child:Text(
                  widget.controller.text.isEmpty ? (_floated ? 'Search branch...' : '') : codePart,
                  style:TextStyle(fontSize:13,fontWeight:FontWeight.w500,color:widget.controller.text.isEmpty?_kMuted:_kText),
                  overflow:TextOverflow.ellipsis)),
                widget.readOnly?const Icon(Icons.lock_outline,size:14,color:_kMuted):const Icon(Icons.arrow_drop_down,size:20,color:_kP),
              ]))))),
        Positioned(left:10,top:0,bottom:0,child:Align(alignment:Alignment.centerLeft,child:Icon(Icons.location_city_rounded,size:14,color:bc))),
        AnimatedBuilder(animation:_ac,builder:(_,__)=>Positioned(top:_top.value,left:28,
          child:GestureDetector(onTap:_open,
            child:Container(color:Colors.white,padding:const EdgeInsets.symmetric(horizontal:4),
              child:Text.rich(TextSpan(text: widget.label, children: [if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]),
                style:TextStyle(fontSize:_sz.value,fontWeight:FontWeight.w600,color:bc,
                  letterSpacing:0.2,decoration:TextDecoration.none)))))),
      ]),
      Builder(
        builder: (context) {
          if (widget.controller.text.isNotEmpty) {
            final s = widget.controller.text.trim();
            final code = s.contains(' - ') ? s.split(' - ').first.trim() : s;
            final match = widget.branches.where((b) => b.branchCode.toString() == code && (widget.selectedOrgCode == null || b.orgCode.toString() == widget.selectedOrgCode.toString())).toList();
            if (match.isNotEmpty) {
              final nm = match.first.branchName;
              if (nm.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Text(nm, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kP, height: 1.2)),
                );
              }
            }
          }
          return const SizedBox.shrink();
        },
      ),
      if(err) Padding(padding:const EdgeInsets.only(top:6,left:2),
        child:Text(widget.errorText!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:_kR,height:1.2))),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Role Dropdown Field
// ═════════════════════════════════════════════════════════════════════════════
class _RoleDropdownField extends StatefulWidget {
  final String label; final TextEditingController controller; final List<AccessCode> roles;
  final bool readOnly; final bool isRequired; final ValueChanged<String> onChanged;
  final String? errorText; final int? selectedOrgCode;
  const _RoleDropdownField({required this.label,required this.controller,required this.roles,
    this.readOnly=false,this.isRequired=false,required this.onChanged,this.errorText,this.selectedOrgCode});
  @override State<_RoleDropdownField> createState() => _RoleDropdownFieldState();
}
class _RoleDropdownFieldState extends State<_RoleDropdownField> with SingleTickerProviderStateMixin {
  final GlobalKey _key=GlobalKey(); OverlayEntry? _ov;
  final TextEditingController _sc=TextEditingController();
  late AnimationController _ac; late Animation<double> _top,_sz;
  bool _isOpen=false;
  FocusNode? _popupFocusNode;

  bool get _hasVal => widget.controller.text.isNotEmpty;
  bool get _floated => _hasVal || _isOpen || widget.errorText!=null;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync:this,duration:const Duration(milliseconds:180),value:_floated?1:0);
    _top = Tween<double>(begin:13,end:-8).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    _sz  = Tween<double>(begin:13,end:10.5).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    widget.controller.addListener((){ setState((){}); _floated?_ac.forward():_ac.reverse(); });
  }
  @override void didUpdateWidget(_RoleDropdownField o) { super.didUpdateWidget(o); _floated?_ac.forward():_ac.reverse(); }
  @override void dispose() { _rm(); _sc.dispose(); _ac.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov=null; _popupFocusNode?.dispose(); _popupFocusNode=null; setState(()=>_isOpen=false); _floated?_ac.forward():_ac.reverse(); }

  void _open() {
    if(widget.readOnly)return; _rm(); _sc.clear();
    _popupFocusNode = FocusNode();
    setState(()=>_isOpen=true); _ac.forward();
    final rb=_key.currentContext?.findRenderObject() as RenderBox?; if(rb==null)return;
    final ov=Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos=rb.localToGlobal(Offset.zero,ancestor:ov); final sz=rb.size;
    int hlIdx = 0;
    final ScrollController scrollCtrl = ScrollController();

    void scrollTo(int idx) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(idx * 40.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      }
    }

    _ov=OverlayEntry(builder:(ctx)=>GestureDetector(behavior:HitTestBehavior.translucent,onTap:_rm,
      child:Material(color:Colors.transparent,child:Stack(children:[
        Positioned(left:pos.dx,top:pos.dy+sz.height+4,width:sz.width.clamp(240.0,360.0),
          child:StatefulBuilder(builder:(c2,ss){
            final filteredRoles = widget.roles;
            final filtered = filteredRoles.where((r){
              final id = r.id?.toString() ?? '';
              final nm = r.accessName.toLowerCase();
              final q = _sc.text.toLowerCase();
              return q.isEmpty || id.contains(q) || nm.contains(q);
            }).toList();

            if (hlIdx >= filtered.length) hlIdx = filtered.isNotEmpty ? filtered.length - 1 : 0;
            if (hlIdx < 0) hlIdx = 0;

            void selectHl() {
              if (filtered.isNotEmpty && hlIdx < filtered.length) {
                final r = filtered[hlIdx];
                widget.onChanged(r.accessName);
                _rm();
              }
            }

            return KeyboardListener(
              focusNode: _popupFocusNode!,
              autofocus: true,
              onKeyEvent: (event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.arrowDown) {
                  ss(() => hlIdx = (hlIdx + 1).clamp(0, filtered.length - 1));
                  scrollTo(hlIdx);
                } else if (key == LogicalKeyboardKey.arrowUp) {
                  ss(() => hlIdx = (hlIdx - 1).clamp(0, filtered.length - 1));
                  scrollTo(hlIdx);
                } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                  selectHl();
                } else if (key == LogicalKeyboardKey.escape) {
                  _rm();
                }
              },
              child: Material(elevation:8,borderRadius:BorderRadius.circular(14),
                child:Container(constraints:const BoxConstraints(maxHeight:180),
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFE2E8F0))),
                  child:Column(mainAxisSize:MainAxisSize.min,children:[
                    Padding(padding:const EdgeInsets.fromLTRB(4, 4, 4, 0),child:TextField(controller:_sc,autofocus:true,
                      onChanged:(_)=>ss((){ hlIdx = 0; }),
                      onSubmitted:(_) => selectHl(),
                      style:const TextStyle(fontSize:13,color:Color(0xFF1E293B)),
                      decoration:InputDecoration(hintText:'Search role...',
                        hintStyle:const TextStyle(fontSize:12,color:Color(0xFFCBD5E1)),
                        prefixIcon:const Icon(Icons.search_rounded,size:16,color:Color(0xFF94A3B8)),
                        filled:true,fillColor:Colors.white,
                        border:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:BorderSide.none),
                        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:BorderSide.none),
                        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:BorderSide.none),
                        contentPadding:const EdgeInsets.symmetric(vertical:6),isDense:true))),
                    const Divider(height:1,color:Color(0xFFE2E8F0)),
                    Flexible(child:ListView.builder(
                      controller: scrollCtrl,
                      padding:const EdgeInsets.symmetric(vertical:0),
                      shrinkWrap:true,
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final r = filtered[idx];
                        final idStr = r.id?.toString() ?? '';
                        final nm = r.accessName;
                        final isSel=widget.controller.text == idStr;
                        final isHl = hlIdx == idx;
                        return InkWell(onTap:(){ widget.onChanged(idStr); _rm(); },
                          child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
                            decoration:BoxDecoration(
                              border:const Border(bottom:BorderSide(color:Color(0xFFF8FAFC))),
                              color:isHl ? const Color(0xFFEEF3FB) : (isSel?const Color(0xFFEEF3FB):Colors.transparent),
                            ),
                            child:Row(children:[
                              Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),margin:const EdgeInsets.only(right:8),
                                decoration:BoxDecoration(color:const Color(0xFFEEF3FB),borderRadius:BorderRadius.circular(4)),
                                child:Text(idStr,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:Color(0xFF3D6EBE)))),
                              Expanded(child:Text(nm,style:TextStyle(fontSize:13,color:isSel?const Color(0xFF3D6EBE):const Color(0xFF1E293B),fontWeight:isSel?FontWeight.w600:FontWeight.w400),overflow:TextOverflow.ellipsis)),
                            ])));
                      },
                    )),
                  ]))),
            );
          })),
      ]))));
    Overlay.of(context).insert(_ov!);
  }

  @override Widget build(BuildContext ctx) {
    final err=widget.errorText!=null; final bc=err?const Color(0xFFDC2626):const Color(0xFF3D6EBE);
    return Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Stack(clipBehavior:Clip.none,children:[
        GestureDetector(onTap:_open,child:Container(key:_key,height:44,
          decoration:BoxDecoration(color:widget.readOnly?const Color(0xFFF8FAFC):Colors.white,
            borderRadius:BorderRadius.circular(12),border:Border.all(color:bc,width:1.5)),
          child:ClipRRect(borderRadius:BorderRadius.circular(10.5),
            child:Padding(padding:const EdgeInsets.fromLTRB(40,12,36,12),
              child:Row(children:[
                Expanded(child:Text(
                  widget.controller.text.isEmpty ? (_floated ? 'Select role' : '') : widget.controller.text,
                  style:TextStyle(fontSize:13,fontWeight:FontWeight.w500,color:widget.controller.text.isEmpty?const Color(0xFF64748B):const Color(0xFF1E293B)),
                  overflow:TextOverflow.ellipsis)),
                widget.readOnly?const Icon(Icons.lock_outline,size:14,color:Color(0xFF64748B)):const Icon(Icons.arrow_drop_down,size:20,color:Color(0xFF3D6EBE)),
              ]))))),
        Positioned(left:10,top:0,bottom:0,child:Align(alignment:Alignment.centerLeft,child:Icon(Icons.admin_panel_settings_outlined,size:14,color:bc))),
        AnimatedBuilder(animation:_ac,builder:(_,__)=>Positioned(top:_top.value,left:28,
          child:GestureDetector(onTap:_open,
            child:Container(color:widget.readOnly?const Color(0xFFF8FAFC):Colors.white,padding:const EdgeInsets.symmetric(horizontal:4),
              child:Text.rich(TextSpan(text: widget.label, children: [if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]),
                style:TextStyle(fontSize:_sz.value,fontWeight:FontWeight.w600,color:bc,
                  letterSpacing:0.2,decoration:TextDecoration.none)))))),
      ]),
      Builder(
        builder: (context) {
          if (widget.controller.text.isNotEmpty) {
            final code = widget.controller.text.trim();
            final match = widget.roles.where((r) => r.id?.toString() == code).toList();
            if (match.isNotEmpty) {
              final nm = match.first.accessName;
              if (nm.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Text(nm, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3D6EBE), height: 1.2)),
                );
              }
            }
          }
          return const SizedBox.shrink();
        },
      ),
      if(err) Padding(padding:const EdgeInsets.only(top:6,left:2),
        child:Text(widget.errorText!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:Color(0xFFDC2626),height:1.2))),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Country Picker Field (full list with mobileLength)
// ═════════════════════════════════════════════════════════════════════════════
class _CountryPickerField extends StatefulWidget {
  final String label; final String? selectedCode; final ValueChanged<_CountryInfo?> onChanged;
  final bool isRequired; final String? errorText;
  final List<_CountryInfo> countries;
  const _CountryPickerField({required this.label,this.selectedCode,required this.onChanged,
    this.isRequired=false,this.errorText,required this.countries});
  @override State<_CountryPickerField> createState() => _CountryPickerFieldState();
}
class _CountryPickerFieldState extends State<_CountryPickerField> with SingleTickerProviderStateMixin {
  final GlobalKey _key=GlobalKey(); OverlayEntry? _ov;
  final TextEditingController _sc=TextEditingController();
  late AnimationController _ac; late Animation<double> _top,_sz;
  bool _isOpen=false;
  FocusNode? _popupFocusNode;

  _CountryInfo? get _sel {
    if (widget.selectedCode == null || widget.selectedCode!.isEmpty) return null;
    try {
      return widget.countries.firstWhere((c) => c.code == widget.selectedCode);
    } catch (_) {
      return _findCountry(widget.selectedCode!);
    }
  }
  bool get _floated => (widget.selectedCode!=null&&widget.selectedCode!.isNotEmpty) || _isOpen || widget.errorText!=null;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync:this,duration:const Duration(milliseconds:180),value:_floated?1:0);
    _top = Tween<double>(begin:13,end:-8).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    _sz  = Tween<double>(begin:13,end:10.5).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
  }
  @override void didUpdateWidget(_CountryPickerField o) { super.didUpdateWidget(o); _floated?_ac.forward():_ac.reverse(); }
  @override void dispose() { _rm(); _sc.dispose(); _ac.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov=null; _popupFocusNode?.dispose(); _popupFocusNode=null; setState(()=>_isOpen=false); _floated?_ac.forward():_ac.reverse(); }

  void _open() {
    _rm(); _sc.clear();
    _popupFocusNode = FocusNode();
    setState(()=>_isOpen=true); _ac.forward();
    final rb=_key.currentContext?.findRenderObject() as RenderBox?; if(rb==null)return;
    final ov=Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos=rb.localToGlobal(Offset.zero,ancestor:ov); final sz=rb.size;
    int hlIdx = 0;
    final ScrollController scrollCtrl = ScrollController();

    void scrollTo(int idx) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(idx * 40.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      }
    }

    _ov=OverlayEntry(builder:(ctx)=>GestureDetector(behavior:HitTestBehavior.translucent,onTap:_rm,
      child:Material(color:Colors.transparent,child:Stack(children:[
        Positioned(left:pos.dx,top:pos.dy+sz.height+4,width:sz.width,
          child:StatefulBuilder(builder:(c2,ss){
            final filtered = widget.countries.where((c){
              final q=_sc.text.toLowerCase();
              return q.isEmpty||c.name.toLowerCase().contains(q)||c.code.toLowerCase().contains(q)||c.dialCode.contains(q);
            }).toList();

            if (hlIdx >= filtered.length) hlIdx = filtered.isNotEmpty ? filtered.length - 1 : 0;
            if (hlIdx < 0) hlIdx = 0;

            void selectHl() {
              if (filtered.isNotEmpty && hlIdx < filtered.length) {
                final c = filtered[hlIdx];
                widget.onChanged(c);
                _rm();
                setState((){});
              }
            }

            return KeyboardListener(
              focusNode: _popupFocusNode!,
              autofocus: true,
              onKeyEvent: (event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.arrowDown) {
                  ss(() => hlIdx = (hlIdx + 1).clamp(0, filtered.length - 1));
                  scrollTo(hlIdx);
                } else if (key == LogicalKeyboardKey.arrowUp) {
                  ss(() => hlIdx = (hlIdx - 1).clamp(0, filtered.length - 1));
                  scrollTo(hlIdx);
                } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                  selectHl();
                } else if (key == LogicalKeyboardKey.escape) {
                  _rm();
                }
              },
              child: Material(elevation:8,borderRadius:BorderRadius.circular(14),
                child:Container(constraints:const BoxConstraints(maxHeight:320),
                  decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:_kBorder)),
                  child:Column(mainAxisSize:MainAxisSize.min,children:[
                    // Header
                    Container(padding:const EdgeInsets.fromLTRB(12,10,12,8),
                      decoration:const BoxDecoration(color:_kPL,
                        borderRadius:BorderRadius.only(topLeft:Radius.circular(13),topRight:Radius.circular(13))),
                      child:const Row(children:[
                        Icon(Icons.public_rounded,size:15,color:_kP),SizedBox(width:6),
                        Text('Select Country',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:_kP,letterSpacing:0.5)),
                      ])),
                    Padding(padding:const EdgeInsets.all(8),child:TextField(controller:_sc,autofocus:true,
                      onChanged:(_)=>ss((){ hlIdx = 0; }),
                      onSubmitted:(_) => selectHl(),
                      style:const TextStyle(fontSize:13,color:_kText),
                      decoration:InputDecoration(hintText:'Search country...',
                        hintStyle:const TextStyle(fontSize:12,color:Color(0xFFCBD5E1)),
                        prefixIcon:const Icon(Icons.search_rounded,size:16,color:_kP),
                        suffixIcon:_sc.text.isNotEmpty?GestureDetector(onTap:(){_sc.clear();ss((){});},child:const Icon(Icons.close_rounded,size:15,color:_kMuted)):null,
                        filled:true,fillColor:_kSurface,
                        border:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kBorder)),
                        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kBorder)),
                        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_kP,width:1.5)),
                        contentPadding:const EdgeInsets.symmetric(vertical:8),isDense:true))),
                    const Divider(height:1,color:_kBorder),
                    Flexible(child:filtered.isEmpty
                      ? const Center(child:Padding(padding:EdgeInsets.all(20),child:Text('No countries found',style:TextStyle(fontSize:13,color:_kMuted))))
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding:EdgeInsets.zero,shrinkWrap:true,itemCount:filtered.length,
                          itemBuilder:(ctx,idx){
                            final c=filtered[idx]; final isSel=widget.selectedCode==c.code;
                            final isHl = hlIdx == idx;
                            final rowBg=isHl ? _kPL.withOpacity(0.8) : (isSel?_kPL:(idx%2==0?Colors.white:const Color(0xFFF0F5FD)));
                            return InkWell(onTap:(){ widget.onChanged(c); _rm(); setState((){}); },
                              child:AnimatedContainer(duration:const Duration(milliseconds:80),
                                padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),
                                color:rowBg,
                                child:Row(children:[
                                  Expanded(child: Text(c.name,style:TextStyle(fontSize:13,color:_kText,fontWeight:isSel?FontWeight.w700:FontWeight.w500))),
                                  if(isSel) const Icon(Icons.check_circle_rounded,size:16,color:_kP),
                                ])));
                          })),
                  ]))),
            );
          })),
      ]))));
    Overlay.of(context).insert(_ov!);
  }

  @override Widget build(BuildContext ctx) {
    final sel=_sel; final err=widget.errorText!=null; final bc=err?_kR:_kP;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Stack(clipBehavior:Clip.none,children:[
        GestureDetector(onTap:_open,child:Container(key:_key,height:44,
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),border:Border.all(color:bc,width:1.5)),
          child:ClipRRect(borderRadius:BorderRadius.circular(10.5),
            child:Padding(padding:const EdgeInsets.fromLTRB(40,12,36,12),
              child:Row(children:[
                Expanded(child:Text(
                  sel!=null ? sel.name : (_floated ? 'Select country' : ''),
                  style:TextStyle(fontSize:13,fontWeight:FontWeight.w500,color:sel!=null?_kText:_kMuted),
                  overflow:TextOverflow.ellipsis)),
                const Icon(Icons.arrow_drop_down,size:20,color:_kP),
              ]))))),
        Positioned(left:10,top:0,bottom:0,child:Align(alignment:Alignment.centerLeft,child:Icon(Icons.language_rounded,size:14,color:bc))),
        AnimatedBuilder(animation:_ac,builder:(_,__)=>Positioned(top:_top.value,left:28,
          child:GestureDetector(onTap:_open,
            child:Container(color:Colors.white,padding:const EdgeInsets.symmetric(horizontal:4),
              child:Text.rich(TextSpan(text: widget.label, children: [if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]),
                style:TextStyle(fontSize:_sz.value,fontWeight:FontWeight.w600,color:bc,
                  letterSpacing:0.2,decoration:TextDecoration.none)))))),
      ]),
      if(err) Padding(padding:const EdgeInsets.only(top:6,left:2),
        child:Text(widget.errorText!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:_kR,height:1.2))),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Mobile Field (country-based length validation)
// ═════════════════════════════════════════════════════════════════════════════
// class _MobileField extends StatefulWidget {
//   final TextEditingController controller;
//   final String? callCode;
//   final String? errorText;
//   final int mobileLength;
  
//   final dynamic onChanged;
//   const _MobileField({required this.controller,this.callCode,this.errorText,this.mobileLength=10,this.onChanged});
//   @override State<_MobileField> createState() => _MobileFieldState();
// }
// class _MobileFieldState extends State<_MobileField> with SingleTickerProviderStateMixin {
//   final FocusNode _fn = FocusNode(); bool _focused = false;
//   late AnimationController _ac; late Animation<double> _top,_sz;

//   bool get _hasCC   => widget.callCode!=null && widget.callCode!.isNotEmpty;
//   bool get _hasVal  => widget.controller.text.isNotEmpty;
//   bool get _floated => _focused || _hasVal || _hasCC || widget.errorText != null;

//   @override void initState() {
//     super.initState();
//     _ac = AnimationController(vsync:this,duration:const Duration(milliseconds:180),value:_floated?1:0);
//     _top = Tween<double>(begin:13,end:-8).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
//     _sz  = Tween<double>(begin:13,end:10.5).animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
//     _fn.addListener((){ setState(()=>_focused=_fn.hasFocus); _floated?_ac.forward():_ac.reverse(); });
//     widget.controller.addListener((){ setState((){}); _floated?_ac.forward():_ac.reverse(); });
//   }
//   @override void didUpdateWidget(_MobileField o) { super.didUpdateWidget(o); _floated?_ac.forward():_ac.reverse(); }
//   @override void dispose() { _fn.dispose(); _ac.dispose(); super.dispose(); }

//   @override Widget build(BuildContext ctx) {
//     final err=widget.errorText!=null; final bc=err?_kR:_kP;
//     return Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
//       Stack(clipBehavior:Clip.none,children:[
//         Container(height:44,
//           decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),border:Border.all(color:bc,width:1.5)),
//           child:ClipRRect(borderRadius:BorderRadius.circular(10.5),
//             child:Row(children:[
//               Padding(padding:const EdgeInsets.only(left:10),
//                 child:Icon(Icons.phone_rounded,size:14,color:bc)),
//               if(_hasCC) ...[
//                 const SizedBox(width:6),
//                 Container(margin:const EdgeInsets.symmetric(vertical:6),
//                   padding:const EdgeInsets.symmetric(horizontal:8),
//                   decoration:BoxDecoration(color:_kPL,borderRadius:BorderRadius.circular(6),border:Border.all(color:_kPB)),
//                   child:Text('+${widget.callCode}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:_kP))),
//               ],
//               Expanded(child:TextField(controller:widget.controller,focusNode:_fn,
//                 keyboardType:TextInputType.phone,
//                 maxLength: widget.mobileLength,
//                 style:const TextStyle(fontSize:13,fontWeight:FontWeight.w500,color:_kText),
//                 decoration:InputDecoration(
//                   counterText: '',
//                   hintText: _floated
//                     ? (_hasCC ? '${widget.mobileLength} digit number' : 'Select country first')
//                     : '',
//                   hintStyle:const TextStyle(fontSize:12.5,color:Color(0xFFCBD5E1)),
//                   border:InputBorder.none,enabledBorder:InputBorder.none,focusedBorder:InputBorder.none,
//                   contentPadding:EdgeInsets.fromLTRB(_hasCC?8:6,14,12,14),isDense:true))),
//             ]))),
//         AnimatedBuilder(animation:_ac,builder:(_,__)=>Positioned(top:_top.value,left:28,
//           child:GestureDetector(onTap:()=>_fn.requestFocus(),
//             child:Container(color:Colors.white,padding:const EdgeInsets.symmetric(horizontal:4),
//               child:Text(
//                 'Mobile Number${_floated ? ' *' : ''}',
//                 style:TextStyle(fontSize:_sz.value,fontWeight:FontWeight.w600,color:bc,
//                   letterSpacing:0.2,decoration:TextDecoration.none)))))),
//       ]),
//       if(err) Padding(padding:const EdgeInsets.only(top:6,left:2),
//         child:Text(widget.errorText!,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:_kR,height:1.2))),
//     ]);
//   }
// }
class _MobileField extends StatefulWidget {
  final TextEditingController controller;
  final String? callCode;
  final String? errorText;
  final int mobileLength;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const _MobileField({
    required this.controller,
    this.callCode,
    this.errorText,
    this.mobileLength = 10,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<_MobileField> createState() => _MobileFieldState();
}

class _MobileFieldState extends State<_MobileField>
    with SingleTickerProviderStateMixin {
  final FocusNode _fn = FocusNode();
  bool _focused = false;
  late AnimationController _ac;
  late Animation<double> _top, _sz;

  bool get _hasCC   => widget.callCode != null && widget.callCode!.isNotEmpty;
  bool get _hasVal  => widget.controller.text.isNotEmpty;
  bool get _floated => _focused || _hasVal || _hasCC || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _floated ? 1 : 0,
    );
    _top = Tween<double>(begin: 13, end: -8)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz = Tween<double>(begin: 13, end: 10.5)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));

    _fn.addListener(() {
      setState(() => _focused = _fn.hasFocus);
      _floated ? _ac.forward() : _ac.reverse();
    });

    widget.controller.addListener(() {
      setState(() {});
      _floated ? _ac.forward() : _ac.reverse();
      // ── FIX: notify parent so it can clear the error on every keystroke ──
      widget.onChanged?.call(widget.controller.text);
    });
  }

  @override
  void didUpdateWidget(_MobileField o) {
    super.didUpdateWidget(o);
    _floated ? _ac.forward() : _ac.reverse();
  }

  @override
  void dispose() {
    _fn.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final err = widget.errorText != null;
    final bc  = err ? _kR : _kP;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: widget.readOnly ? _kSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bc, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(Icons.phone_rounded, size: 14, color: bc),
                    ),
                    if (_hasCC) ...[
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: _kPL,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _kPB),
                        ),
                        child: Text(
                          '+${widget.callCode}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kP,
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _fn,
                        readOnly: widget.readOnly,
                        keyboardType: TextInputType.phone,
                        maxLength: widget.mobileLength,
                        inputFormatters: [_RejectingInputFormatter(RegExp(r'^\d*$'), () {
                          if (widget.onChanged != null) widget.onChanged!('invalid');
                        })],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kText,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: _floated
                              ? (_hasCC
                                  ? '${widget.mobileLength} digit number'
                                  : 'Select country first')
                              : '',
                          hintStyle: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFCBD5E1),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.fromLTRB(
                              _hasCC ? 8 : 6, 14, 12, 14),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ac,
              builder: (_, __) => Positioned(
                top: _top.value,
                left: 28,
                child: GestureDetector(
                  onTap: widget.readOnly ? null : () => _fn.requestFocus(),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text.rich(
                      TextSpan(
                        text: 'Mobile Number',
                        children: [
                          if (!widget.readOnly)
                            const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: _sz.value,
                        fontWeight: FontWeight.w600,
                        color: bc,
                        letterSpacing: 0.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (err)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kR,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}
// ═════════════════════════════════════════════════════════════════════════════
//  Picture Upload Box
// ═════════════════════════════════════════════════════════════════════════════
class _PictureUploadBox extends StatefulWidget {
  final int orgCode;
  final String? initialPath;
  final ValueChanged<String?> onUploaded;
  final ValueChanged<_PendingPicture?> onPending;
  final bool isEditMode;
  final bool isRequired;
  final bool hasError;
  final String? errorMsg;

  const _PictureUploadBox({
    required this.orgCode,
    this.initialPath,
    required this.onUploaded,
    required this.onPending,
    this.isEditMode = false,
    this.isRequired = false,
    this.hasError = false,
    this.errorMsg, required GlobalKey<_PictureUploadBoxState> key,
  });

  @override State<_PictureUploadBox> createState() => _PictureUploadBoxState();
}

class _PendingPicture {
  final Uint8List bytes;
  final String fileName;
  const _PendingPicture({required this.bytes, required this.fileName});
}

// class _PictureUploadBoxState extends State<_PictureUploadBox> {
//   final _svc = ProfileService();

//   String?  _uploadedPath;
//   String?  _previewUrl;
//   Uint8List? _pendingBytes;
//   String?  _pendingName;

//   @override void initState() {
//     super.initState();
//     _uploadedPath = widget.initialPath;
//     if (_uploadedPath?.isNotEmpty == true) _loadPreview();
//   }

//   Future<void> _loadPreview() async {
//     final url = await _svc.getProfilePictureUrl(orgId: widget.orgCode, filePath: _uploadedPath!);
//     if (mounted) setState(() => _previewUrl = url);
//   }

 
// // Future<void> _pick() async {
// //   final res = await FilePicker.platform.pickFiles(
// //     type: FileType.image,
// //     withData: true,
// //   );
// //   if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;

// //   final bytes = res.files.first.bytes!;
// //   final fileName = res.files.first.name;

// //   setState(() {
// //     _pendingBytes = bytes;
// //     _pendingName  = fileName;
// //     _previewUrl   = null;
// //   });

// //   widget.onPending(_PendingPicture(bytes: bytes, fileName: fileName));
// //   widget.onUploaded('__pending__');
// // }

// Future<void> _pick() async {
//   try {
//     FilePickerResult? res;

//     if (kIsWeb) {
//       // On web (Tomcat/any server), explicitly request bytes
//       res = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         withData: true,
//         allowMultiple: false,
//       );
//     } else {
//       res = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         withData: true,
//       );
//     }

//     if (res == null || res.files.isEmpty) return;

//     final pickedFile = res.files.first;

//     Uint8List? bytes;

//     if (kIsWeb) {
//       // On web, bytes come directly from the result
//       bytes = pickedFile.bytes;
//     } else {
//       // On native, read from path if bytes are null
//       if (pickedFile.bytes != null) {
//         bytes = pickedFile.bytes;
//       } else if (pickedFile.path != null) {
//         bytes = await File(pickedFile.path!).readAsBytes();
//       }
//     }

//     if (bytes == null || bytes.isEmpty) {
//       debugPrint('_PictureUploadBox: bytes are null after pick — aborting');
//       return;
//     }

//     final fileName = pickedFile.name;

//     setState(() {
//       _pendingBytes = bytes;
//       _pendingName  = fileName;
//       _previewUrl   = null;
//     });

//     widget.onPending(_PendingPicture(bytes: bytes, fileName: fileName));
//     widget.onUploaded('__pending__');

//   } catch (e, st) {
//     debugPrint('_PictureUploadBox._pick error: $e\n$st');
//     // Optionally show a toast/snackbar here
//   }
// }
// Future<String?> uploadIfPending() async {
//   if (_pendingBytes == null) return _uploadedPath;
//   try {
//     final path = await _svc.uploadProfilePicture(
//       orgId: widget.orgCode,
//       fileBytes: _pendingBytes!,
//       fileName: _pendingName!,
//     );
//     if (path != null) {
//       _uploadedPath = path;
//       _pendingBytes = null;
//       _pendingName  = null;
//     }
//     return path;
//   } catch (e) {
//     debugPrint('uploadIfPending error: $e');
//     return null;
//   }
// }
//   void _del() {
//     setState(() {
//       _uploadedPath = null;
//       _previewUrl   = null;
//       _pendingBytes = null;
//       _pendingName  = null;
//     });
//     widget.onPending(null);
//     widget.onUploaded(null);
//   }

//   bool get _hasPicture =>
//       (_pendingBytes != null) || (_uploadedPath?.isNotEmpty == true);


//   @override Widget build(BuildContext ctx) {
//     final borderColor = widget.hasError ? _kR : (_hasPicture ? _kPB : _kBorder);

//     Widget previewChild;
//     if (_pendingBytes != null) {
//       previewChild = ClipRRect(
//         borderRadius: BorderRadius.circular(13),
//         child: Image.memory(_pendingBytes!, fit: BoxFit.cover,
//             width: double.infinity, height: double.infinity));
//     } else if (_previewUrl != null) {
//       previewChild = ClipRRect(
//         borderRadius: BorderRadius.circular(13),
//         child: Image.network(_previewUrl!, fit: BoxFit.cover,
//             width: double.infinity, height: double.infinity));
//     } else {
//       previewChild = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//         Container(width: 44, height: 44,
//             decoration: const BoxDecoration(color: _kPL, shape: BoxShape.circle),
//             child: const Icon(Icons.cloud_upload_outlined, size: 22, color: _kP)),
//         const SizedBox(height: 10),
//         const Text('Click to upload',
//             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kP)),
//         const SizedBox(height: 4),
//         const Text('PNG, JPG (max 5 MB)',
//             style: TextStyle(fontSize: 10, color: _kMuted), textAlign: TextAlign.center),
//       ]);
//     }

//     return Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
//       Padding(padding: const EdgeInsets.only(bottom: 8),
//           child: Text('Profile Picture${widget.isRequired ? ' ' : ''}',
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
//                 color: widget.hasError ? _kR : _kP, letterSpacing: 0.2),
//             textAlign: TextAlign.center)),
//       GestureDetector(
//           onTap: _pick,
//           child: MouseRegion(cursor: SystemMouseCursors.click,
//               child: AspectRatio(aspectRatio: 1,
//                   child: Container(
//                       decoration: BoxDecoration(
//                           color: _hasPicture ? Colors.white : _kSurface,
//                           borderRadius: BorderRadius.circular(14),
//                           border: Border.all(color: borderColor, width: widget.hasError ? 2.0 : 1.5)),
//                       child: previewChild)))),
//       if (_hasPicture) ...[
//         const SizedBox(height: 10),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _mini('Edit', Icons.edit_rounded, _kP, _kPL, _kPB, onTap: _pick),
//           const SizedBox(width: 8),
//           _mini('Remove', Icons.delete_outline_rounded, _kR, _kR, _kR,
//               textColor: Colors.white, onTap: _del),
//         ]),
//       ],
//       if (widget.hasError && widget.errorMsg != null) ...[
//         const SizedBox(height: 6),
//         Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
//             child: Text(widget.errorMsg!,
//                 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2)))],
//     ]);
//   }

//   Widget _mini(String lbl, IconData ic, Color fg, Color bg, Color bd,
//       {VoidCallback? onTap, Color? textColor}) =>
//       MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: onTap,
//           child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7),
//                   border: Border.all(color: bd)),
//               child: Row(mainAxisSize: MainAxisSize.min, children: [
//                 Icon(ic, size: 12, color: textColor ?? fg), const SizedBox(width: 4),
//                 Text(lbl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
//                     color: textColor ?? fg)),
//               ]))));
// }
class _PictureUploadBoxState extends State<_PictureUploadBox> {
  final _svc = ProfileService();

  String?    _uploadedPath;
  String?    _previewUrl;
  Uint8List? _pendingBytes;
  String?    _pendingName;

  @override
  void initState() {
    super.initState();
    _uploadedPath = widget.initialPath;
    if (_uploadedPath?.isNotEmpty == true) _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final url = await _svc.getProfilePictureUrl(
          orgId: widget.orgCode, filePath: _uploadedPath!);
      if (mounted) setState(() => _previewUrl = url);
    } catch (e) {
      debugPrint('_loadPreview error: $e');
    }
  }

  Future<String?> uploadIfPending() async {
    if (_pendingBytes == null) return _uploadedPath;
    try {
      final path = await _svc.uploadProfilePicture(
        orgId:     widget.orgCode,
        fileBytes: _pendingBytes!,
        fileName:  _pendingName!,
      );
      if (path != null) {
        _uploadedPath = path;
        _pendingBytes = null;
        _pendingName  = null;
      }
      return path;
    } catch (e) {
      debugPrint('uploadIfPending error: $e');
      return null;
    }
  }

  // ── Core pick logic ───────────────────────────────────────────────────────
  Future<void> _pick() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type:     FileType.image,
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;

      final f = res.files.first;
      Uint8List? bytes = f.bytes;

      if (bytes == null && f.path != null) {
        if (!kIsWeb) {
          bytes = await File(f.path!).readAsBytes();
        }
      }
      
      if (bytes == null) return;
      
      // Validate size (5 MB max)
      if (f.size > 5 * 1024 * 1024) {
        debugPrint('File too large: ${f.size} bytes');
        return;
      }

      if (!mounted) return;
      setState(() {
        _pendingBytes = bytes;
        _pendingName  = f.name;
        _previewUrl   = null;
      });
      widget.onPending(_PendingPicture(bytes: bytes!, fileName: f.name));
      widget.onUploaded('__pending__');
    } catch (e, st) {
      debugPrint('_pick error: $e\n$st');
    }
  }

  void _del() {
    setState(() {
      _uploadedPath = null;
      _previewUrl   = null;
      _pendingBytes = null;
      _pendingName  = null;
    });
    widget.onPending(null);
    widget.onUploaded(null);
  }

  bool get _hasPicture =>
      (_pendingBytes != null) || (_uploadedPath?.isNotEmpty == true);

  @override
  Widget build(BuildContext ctx) {
    final borderColor =
        widget.hasError ? _kR : (_hasPicture ? _kPB : _kBorder);

    Widget previewChild;
    if (_pendingBytes != null) {
      previewChild = ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.memory(_pendingBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity));
    } else if (_previewUrl != null) {
      previewChild = ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.network(_previewUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity));
    } else {
      previewChild = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: _kPL, shape: BoxShape.circle),
                child: const Icon(Icons.cloud_upload_outlined,
                    size: 22, color: _kP)),
            const SizedBox(height: 10),
            const Text('Click to upload',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kP)),
            const SizedBox(height: 4),
            const Text('PNG, JPG (max 5 MB)',
                style: TextStyle(fontSize: 10, color: _kMuted),
                textAlign: TextAlign.center),
          ]);
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  'Profile Picture${widget.isRequired ? ' ' : ''}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.hasError ? _kR : _kP,
                      letterSpacing: 0.2),
                  textAlign: TextAlign.center)),
          GestureDetector(
              onTap: _pick,
              child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                          decoration: BoxDecoration(
                              color: _hasPicture
                                  ? Colors.white
                                  : _kSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: borderColor,
                                  width: widget.hasError ? 2.0 : 1.5)),
                          child: previewChild)))),
          if (_hasPicture) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _mini('Edit', Icons.edit_rounded, _kP, _kPL, _kPB,
                  onTap: _pick),
              const SizedBox(width: 8),
              _mini('Remove', Icons.delete_outline_rounded, _kR, _kR, _kR,
                  textColor: Colors.white, onTap: _del),
            ]),
          ],
          if (widget.hasError && widget.errorMsg != null) ...[
            const SizedBox(height: 6),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(widget.errorMsg!,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _kR,
                        height: 1.2)))
          ],
        ]);
  }

  Widget _mini(String lbl, IconData ic, Color fg, Color bg, Color bd,
          {VoidCallback? onTap, Color? textColor}) =>
      MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: bd)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(ic, size: 12, color: textColor ?? fg),
                    const SizedBox(width: 4),
                    Text(lbl,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor ?? fg)),
                  ]))));
}
// ═════════════════════════════════════════════════════════════════════════════
//  Picture View Widget
// ═════════════════════════════════════════════════════════════════════════════
class _PictureViewWidget extends StatefulWidget {
  final int orgCode; final String? picturePath;
  const _PictureViewWidget({required this.orgCode,this.picturePath});
  @override State<_PictureViewWidget> createState() => _PictureViewWidgetState();
}
class _PictureViewWidgetState extends State<_PictureViewWidget> {
  final _svc=ProfileService(); String? _url; bool _loading=true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    if(widget.picturePath==null||widget.picturePath!.isEmpty){ setState(()=>_loading=false); return; }
    final u=await _svc.getProfilePictureUrl(orgId:widget.orgCode,filePath:widget.picturePath!);
    if(mounted) setState((){_url=u;_loading=false;});
  }
  @override Widget build(BuildContext ctx) {
    if(_loading) return Container(width:72,height:72,decoration:BoxDecoration(color:_kSurface,borderRadius:BorderRadius.circular(12)),
      child:const Center(child:SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:_kP))));
    if(_url==null) return Container(width:72,height:72,decoration:BoxDecoration(color:_kPL,borderRadius:BorderRadius.circular(12),border:Border.all(color:_kPB)),
      child:const Icon(Icons.person_rounded,size:32,color:_kP));
    return Container(width:72,height:72,
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),border:Border.all(color:_kPB,width:1.5),
        image:DecorationImage(image:NetworkImage(_url!),fit:BoxFit.cover)));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Users (main screen)
// ═════════════════════════════════════════════════════════════════════════════
class Users extends StatefulWidget {
  final AccessPrivileges? accessPrivileges;
  const Users({super.key, this.accessPrivileges});
  @override State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  final _userSvc = UserAccountService();
  final _authSvc = AuthService();
  final _orgSvc  = OrganizationService();
  final _branchSvc = BranchService();

  _ViewMode _view   = _ViewMode.list;
  bool _isLoading   = true;
  bool _isFetching  = false;
  bool _isSaving    = false;
  bool _isDeleting  = false;
  bool _delConfirmed= false;
  bool _isAdmin     = false;
  String? _adminOrgLabel;
  String _search    = '';
  String _orgFilter = '';
  String _branchFilter = '';
  bool _showFilterFields = false;
  int    _page      = 0;
  static const _pageSize = 10;
  int    _totalElements = 0;
  int    _activeCount = 0;
  int    _inactiveCount = 0;
  Timer? _debounce;
  int?   _accountPgmId;

  List<UserAccount>        _users = [];
  List<Map<String,dynamic>> _orgs = [];
  List<Branch>             _branches = [];
  List<AccessCode>         _roles = [];
  List<Map<String,dynamic>> _apiCountries = [];
  UserAccount? _selected;

  final Map<String,String?> _errors = {};

  final _orgCodeCtrl   = TextEditingController();
  final _branchCtrl    = TextEditingController();
  final _userCodeCtrl  = TextEditingController();
  final _titleCtrl     = TextEditingController();
  final _firstCtrl     = TextEditingController();
  final _midCtrl       = TextEditingController();
  final _lastCtrl      = TextEditingController();
  final _dobCtrl       = TextEditingController();
  final _genderCtrl    = TextEditingController();
  final _mobileCtrl    = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _statusCtrl    = TextEditingController();
  final _regDateCtrl   = TextEditingController();
  final _roleCtrl      = TextEditingController();

  String? _countryCode;
  String? _callCode;
  String? _picturePath;
  int     _uploadOrgCode = 0;
  int     _mobileLength  = 10; // FIX: dynamic mobile length based on country

  final GlobalKey<_PictureUploadBoxState> _pictureBoxKey = GlobalKey();
  _PendingPicture? _pendingPicture;

  @override void initState() { super.initState(); _loadData(); _fetchAccountPgmId(); }

  Future<void> _fetchAccountPgmId() async {
    try {
      final programs = await ProgramService().getAllPrograms();
      final pgm = programs.firstWhere(
        (p) => p.descn.toLowerCase().trim() == 'user account' || p.descn.toLowerCase().trim() == 'user accounts',
      );
      _accountPgmId = pgm.pgmId;
    } catch (_) {}
  }
  @override void dispose() {
    _debounce?.cancel();
    for(final c in [_orgCodeCtrl,_branchCtrl,_userCodeCtrl,_titleCtrl,_firstCtrl,_midCtrl,_lastCtrl,_dobCtrl,_genderCtrl,_mobileCtrl,_emailCtrl,_statusCtrl,_regDateCtrl,_roleCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    final useInlineLoading = !_isLoading;
    if (useInlineLoading) {
      setState(() => _isFetching = true);
    }
    try {
      final limit = _pageSize;
      final offset = _page * limit;
      final result = await _userSvc.getUsersPaginated(
        offset: offset,
        limit: limit,
        search: _search,
        orgCode: _orgFilter.isNotEmpty ? int.tryParse(_orgFilter) : null,
        brncd: _branchFilter.isNotEmpty ? int.tryParse(_branchFilter) : null,
      );
      if (mounted) {
        setState(() {
          final content = result['content'] as List? ?? [];
          _users = content.map((json) => UserAccount.fromJson(Map<String, dynamic>.from(json))).toList();
          _totalElements = result['totalElements'] as int? ?? 0;
          _activeCount = result['activeCount'] as int? ?? 0;
          _inactiveCount = result['inactiveCount'] as int? ?? 0;
          _isFetching = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _isLoading = false;
        });
        _msg('Unable to load user accounts: $e',err:true);
      }
    }
  }

  Future<void> _loadData() async {
    setState(()=>_isLoading=true);
    try {
      var currentUser = _authSvc.currentUser;
      if (currentUser == null) {
        currentUser = await _authSvc.getUser();
      }
      String? roleType = currentUser?.roleType;
      if (kIsWeb) {
        final sessionRole = html.window.sessionStorage['role_type'];
        if (sessionRole != null && sessionRole.isNotEmpty) {
          roleType = sessionRole;
        }
      }
      final isAdmin = roleType?.toUpperCase() == 'ADMIN';

      List<Map<String,dynamic>> orgs = [];
      if (isAdmin) {
        if (currentUser?.orgCode != null && currentUser?.userScd != null) {
          orgs = await _orgSvc.getOrganizationsByUser(currentUser!.orgCode!, currentUser.userScd!);
        }
        if (orgs.isEmpty && currentUser?.orgCode != null) {
          final fallbackOrg = await _orgSvc.getOrganizationByCode(currentUser!.orgCode!);
          orgs = fallbackOrg != null ? [fallbackOrg] : [];
        }
      } else {
        orgs = await _orgSvc.getAllOrganizations();
      }

      final r = await Future.wait([
        Future.value(orgs), 
        _branchSvc.getAllBranches(),
        AddressService().getCountries().catchError((_) => <Map<String, dynamic>>[])
      ]);
      final loadedOrgs = r[0] as List<Map<String,dynamic>>;
      String? adminOrgLabel;
      if (isAdmin && loadedOrgs.isNotEmpty) {
        if (loadedOrgs.length == 1) {
          final org = loadedOrgs.first;
          final orgName = (org['orgName'] ?? org['name'] ?? '').toString();
          final orgCode = org['orgCode']??org['orgcode']?.toString() ?? '';
          if (orgCode.isNotEmpty) {
            adminOrgLabel = '$orgCode - $orgName';
          }
        } else if (currentUser?.orgCode != null) {
          final matchingOrg = loadedOrgs.firstWhere(
            (o) => o['orgCode']??o['orgcode']?.toString() == currentUser!.orgCode!.toString(),
            orElse: () => <String, dynamic>{},
          );
          if (matchingOrg.isNotEmpty) {
            final orgName = (matchingOrg['orgName'] ?? matchingOrg['name'] ?? '').toString();
            final orgCode = matchingOrg['orgCode']??matchingOrg['orgcode']?.toString() ?? '';
            adminOrgLabel = '$orgCode - $orgName';
          }
        }
      }

      setState(() {
        _orgs = loadedOrgs;
        _branches = r[1] as List<Branch>;
        _apiCountries = r[2] as List<Map<String,dynamic>>;
        _isAdmin = isAdmin;
        _adminOrgLabel = adminOrgLabel;
        if (_countryCode != null) {
          final ci = _findCountryFromApi(_countryCode!);
          if (ci != null) {
            _callCode = ci.dialCode;
            _mobileLength = ci.mobileLength;
          }
        }
      });
      await _fetchUsers();
    } catch (_) {
      setState(()=>_isLoading=false);
      _msg('Unable to load user accounts.',err:true);
    }
  }

  void _msg(String m,{bool err=false}) => _Toast.show(context,m,isError:err);

  List<_CountryInfo> get _resolvedCountries {
    if (_apiCountries.isEmpty) return _kCountries;
    return _apiCountries.map((c) => _mapDbToCountryInfo(c)).toList();
  }

  bool get _shouldShowBranchFilter {
    if (!_isAdmin || _orgs.length > 1) {
      if (_orgFilter.isEmpty) return false;
      return _branches.any((b) => b.orgCode.toString() == _orgFilter);
    } else {
      if (_orgs.isEmpty) return false;
      final lockedOrgCode = _orgs.first['orgCode']?.toString() ?? '';
      return _branches.any((b) => b.orgCode.toString() == lockedOrgCode);
    }
  }

  _CountryInfo? _findCountryFromApi(String codeOrName) {
    if (codeOrName.isEmpty) return null;
    final lower = codeOrName.toLowerCase();
    for (final c in _apiCountries) {
      final ccode = (c['countrycode'] ?? c['code'] ?? '').toString().trim().toLowerCase();
      final cname = (c['countryname'] ?? c['name'] ?? '').toString().trim().toLowerCase();
      if (ccode == lower || cname == lower) {
        return _mapDbToCountryInfo(c);
      }
    }
    return _findCountry(codeOrName);
  }

  Widget _scroll({required Widget child}) => SingleChildScrollView(key: ValueKey('$_view-${_selected?.userCode ?? ''}'), padding:const EdgeInsets.all(20),child:child);

  Widget _hdr({required String title,List<Widget> actions=const[]}) =>
      Padding(padding:const EdgeInsets.only(bottom:20),
        child:Row(children:[
          Expanded(child:Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:_kText,letterSpacing:-0.3))),
          ...actions,
        ]));

  Widget _card({required Widget child,EdgeInsets? padding}) =>
      Container(width:double.infinity,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:_kBorder)),
        clipBehavior:Clip.antiAlias,padding:padding,child:child);

  Widget _stat(String n,String l,Color nc,Color bg,Color bd,IconData ic,Color icc) =>
      Container(width:180,padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),border:Border.all(color:bd)),
        child:Row(mainAxisSize:MainAxisSize.min,children:[
          Container(width:36,height:36,decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(9)),child:Icon(ic,size:18,color:icc)),
          const SizedBox(width:10),
          Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
            Text(n,style:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:nc,height:1.1)),
            Text(l,style:const TextStyle(fontSize:10,color:_kMuted)),
          ]),
        ]));

  Widget _btn(String lbl,{Color bg=Colors.white,Color fg=_kMuted,Color bd=_kBorder,IconData? ic,VoidCallback? onTap}) =>
      MouseRegion(cursor:SystemMouseCursors.click,child:GestureDetector(onTap:onTap,
        child:Container(padding:const EdgeInsets.symmetric(horizontal:18,vertical:9),
          decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(10),border:Border.all(color:bd,width:1.5)),
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            if(ic!=null)...[Icon(ic,size:15,color:fg),const SizedBox(width:6)],
            Text(lbl,style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:fg)),
          ]))));

  Widget _pgBtn(String lbl,{required bool en,required VoidCallback onTap}) =>
      MouseRegion(cursor:en?SystemMouseCursors.click:SystemMouseCursors.forbidden,child:GestureDetector(onTap:en?onTap:null,
        child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(8),border:Border.all(color:_kBorder)),
          child:Text(lbl,style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:en?_kMuted:const Color(0xFFCBD5E1))))));

  Widget _badge(bool act) => Container(
    padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),
    decoration:BoxDecoration(color:act?_kGL:_kRL,borderRadius:BorderRadius.circular(20)),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      Container(width:5,height:5,decoration:BoxDecoration(color:act?_kG:_kR,shape:BoxShape.circle)),
      const SizedBox(width:4),
      Text(act?'Active':'Inactive',style:TextStyle(color:act?_kG:_kR,fontWeight:FontWeight.w700,fontSize:10)),
    ]));

  Widget _fBtn(String lbl,IconData ic,Color bg,Color fg,Color bd,{VoidCallback? onTap}) =>
      MouseRegion(cursor:onTap==null?SystemMouseCursors.forbidden:SystemMouseCursors.click,child:GestureDetector(onTap:onTap,
        child:AnimatedContainer(duration:const Duration(milliseconds:150),
          padding:const EdgeInsets.symmetric(horizontal:20,vertical:9),
          decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(10),border:Border.all(color:bd,width:1.5)),
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            Icon(ic,size:15,color:fg),const SizedBox(width:6),
            Text(lbl,style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:fg)),
          ]))));

  Widget _rowBtn(IconData ic,Color c,VoidCallback t) =>
      MouseRegion(cursor:SystemMouseCursors.click,child:GestureDetector(onTap:t,
        child:Container(width:32,height:32,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(8),border:Border.all(color:_kBorder)),
          child:Icon(ic,color:c,size:16))));

  Widget _dr(String k,String v,{bool red=false}) => Row(children:[
    SizedBox(width:150,child:Text(k,style:const TextStyle(fontSize:12,color:_kMuted))),
    Text(v,style:TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:red?_kR:_kText)),
  ]);

  void _startView(_ViewMode v,[UserAccount? u]){
    setState((){
      _view=v;
      _selected=u;
      _delConfirmed=false;
      _errors.clear();
      _pendingPicture=null;
      if (v == _ViewMode.list) {
        _page = 0;
        _search = '';
      }
    });
    if (v == _ViewMode.list) {
      _fetchUsers();
    } else if(v==_ViewMode.create)_prep(null); else if(v!=_ViewMode.list)_prep(u);
  }

  void _prep(UserAccount? u){
    if (u == null && _adminOrgLabel != null) {
      _orgCodeCtrl.text = _adminOrgLabel!;
    } else {
      _orgCodeCtrl.text  = u?.orgCode.toString()??'';
    }
    final branch = (u?.branchCode != null && u?.orgCode != null)
      ? _branches.firstWhere((b) => b.branchCode == u!.branchCode && b.orgCode == u.orgCode, orElse: () => Branch(orgCode: 0, branchCode: 0, branchName: ''))
      : null;
    _branchCtrl.text   = branch != null ? '${branch.branchCode} - ${branch.branchName}' : '';
    _userCodeCtrl.text = u?.userCode.toString()??'';
    _titleCtrl.text    = u?.title??'';
    _firstCtrl.text    = u?.fName??'';
    _midCtrl.text      = u?.mName??'';
    _lastCtrl.text     = u?.lName??'';
    _dobCtrl.text      = u?.dob??'';
    final g=u?.gender??'';
    _genderCtrl.text=g=='M'?'Male':(g=='F'?'Female':(g=='O'?'Others':''));
    _countryCode       = u?.country?.isNotEmpty==true?u!.country:(u == null ? 'IN' : null);
    _mobileCtrl.text   = u?.mobile??'';
    _emailCtrl.text    = u?.emailId??'';
    _picturePath       = u?.picture;
    _statusCtrl.text   = (u?.status??1)==1?'Active':'Inactive';
    _regDateCtrl.text  = u?.regDate??'';
    final rt = u?.roleType ?? '';
    _roleCtrl.text = rt;
    if (u == null && _isAdmin) _roleCtrl.text = '3'; // Default to End User role ID
    if(_countryCode!=null){
      final ci = _findCountryFromApi(_countryCode!);
      _callCode = ci?.dialCode;
      _mobileLength = ci?.mobileLength ?? 10;
    } else {
      _callCode = u?.callCode;
      _mobileLength = 10;
    }
    _uploadOrgCode=u?.orgCode??0;
    _pendingPicture=null;
    
    if (u != null && u.orgCode != null) {
      final codePart = u.orgCode.toString();
      if (codePart.isNotEmpty) {
        AccessCodeService().getRolesByOrganization(codePart).then((roles) {
          if (mounted) {
            setState(() => _roles = roles);
          }
        }).catchError((e) {
          debugPrint('Error fetching roles in _prep: $e');
        });
      }
    }
    
    setState((){});
  }

  String _orgDisp(dynamic code){ final s=code.toString(); final o=_orgs.firstWhere((e)=>e['orgCode']??e['orgcode']?.toString()==s,orElse:()=><String,dynamic>{}); if(o.isEmpty)return s; final n=(o['orgName']??o['name']??'').toString(); return n.isEmpty?s:'$s - $n'; }
  String _branchDisp(dynamic code,[dynamic orgCode]){
    final s=code?.toString()??'';
    if(s.isEmpty) return '—';
    final b=_branches.firstWhere((e){
      final matchCode = e.branchCode.toString()==s;
      if(orgCode!=null) return matchCode && e.orgCode.toString()==orgCode.toString();
      return matchCode;
    },orElse:() => Branch(orgCode: 0, branchCode: int.tryParse(s)??0, branchName: ''));
    return b.branchName.isNotEmpty ? '$s - ${b.branchName}' : 'no';
  }
  // FIX: Added 'O' for Others
  String _gpay(String v)=>v=='Male'?'M':(v=='Female'?'F':(v=='Others'?'O':v));
  int    _spay(String v)=>v=='Active'?1:0;

  bool _validate() {
    final errs = <String,String?>{};
    bool ok = true;
    final nameExp = RegExp(r'^[a-zA-Z\s]+$');
    final numExp = RegExp(r'^[0-9]+$');
    if(_orgCodeCtrl.text.trim().isEmpty){ errs['org']='Organization is required'; ok=false; }
    if(_branchCtrl.text.trim().isEmpty){ errs['branch']='Branch is required'; ok=false; }
    if(_userCodeCtrl.text.trim().isEmpty){ errs['userCode']='User Code is required'; ok=false; }
    if(_titleCtrl.text.trim().isEmpty){ errs['title']='Title is required'; ok=false; }
    
    if(_firstCtrl.text.trim().isEmpty){ errs['firstName']='First Name is required'; ok=false; }
    else { final e = orgnamevalid(_firstCtrl.text.trim()); if(e!=null){ errs['firstName']=e; ok=false; } }
    
    if(_midCtrl.text.trim().isNotEmpty) { final e = orgnamevalid(_midCtrl.text.trim()); if(e!=null){ errs['midName']=e; ok=false; } }
    
    if(_lastCtrl.text.trim().isEmpty){ errs['lastName']='Last Name is required'; ok=false; }
    else { final e = orgnamevalid(_lastCtrl.text.trim()); if(e!=null){ errs['lastName']=e; ok=false; } }
    
    if(_dobCtrl.text.trim().isEmpty){ errs['dob']='Date of Birth is required'; ok=false; }
    if(_genderCtrl.text.trim().isEmpty){ errs['gender']='Gender is required'; ok=false; }
    if(_countryCode==null||_countryCode!.isEmpty){ errs['country']='Country is required'; ok=false; }
    
    if(_mobileCtrl.text.trim().isEmpty){
      errs['mobile']='Mobile Number is required'; ok=false;
    } else if(_mobileCtrl.text.trim().length!=_mobileLength){
      errs['mobile']='Must be exactly $_mobileLength digits'; ok=false;
    }
    
    if(_emailCtrl.text.trim().isEmpty){ errs['email']='Email is required'; ok=false; }
    else if(!_emailCtrl.text.trim().contains('@')){ errs['email']='Enter a valid email with @'; ok=false; }
    if(_statusCtrl.text.trim().isEmpty){ errs['status']='Status is required'; ok=false; }
    if(_regDateCtrl.text.trim().isEmpty){ errs['regDate']='Registration Date is required'; ok=false; }
    setState(()=>_errors..clear()..addAll(errs));
    return ok;
  }

  Future<void> _save() async {
    if(!_validate()){ _msg('Please fill all required fields.',err:true); return; }
    final oc=int.tryParse(_orgCodeCtrl.text.trim().split(' ').first.replaceAll(RegExp(r'[^0-9]'),''));
    final uc=_userCodeCtrl.text.trim();
    if(oc==null){ _msg('Organization Code must be numeric.',err:true); return; }
    if(uc.isEmpty){ _msg('User Code is required.',err:true); return; }

    setState(()=>_isSaving=true);
    try {
      String? finalPicturePath = _picturePath;
      if (_pendingPicture != null) {
        final svc = ProfileService();
        final uploaded = await svc.uploadProfilePicture(
          orgId: oc,
          fileBytes: _pendingPicture!.bytes,
          fileName: _pendingPicture!.fileName,
        );
        if (uploaded == null) {
          _msg('Failed to upload profile picture. Please try again.', err: true);
          setState(() => _isSaving = false);
          return;
        }
        finalPicturePath = uploaded;
      } else if (finalPicturePath == '__pending__') {
        finalPicturePath = await _pictureBoxKey.currentState?.uploadIfPending();
      }

      final u=UserAccount(orgCode:oc,userCode: uc.toString(),title:_titleCtrl.text.trim(),fName:_firstCtrl.text.trim(),
        mName:_midCtrl.text.trim(),lName:_lastCtrl.text.trim(),emailId:_emailCtrl.text.trim(),
        mobile:_mobileCtrl.text.trim(),gender:_gpay(_genderCtrl.text.trim()),regDate:_formatForBackend(_regDateCtrl.text.trim()),
        status:_spay(_statusCtrl.text.trim()),branchCode:int.tryParse(_branchCtrl.text.trim().split(' - ').first.trim()),
        picture:finalPicturePath??'',dob:_formatForBackend(_dobCtrl.text.trim()),country:_countryCode??'',callCode:_callCode??'',
        pgmId: _accountPgmId,
        roleType:_roleCtrl.text.trim().isNotEmpty ? _roleCtrl.text.trim() : null);

      if(_view==_ViewMode.create){
        await _userSvc.createUser(u);
        OperationalLogService().logAction(programId: 'USER ACCOUNTS', action: 'I');
        _msg('User created successfully.');
      } else {
        await _userSvc.updateUser(u);
        OperationalLogService().logAction(programId: 'USER ACCOUNTS', action: 'U');
        _msg('User updated successfully.');
      }
      await _loadData(); _startView(_ViewMode.list);
    } catch(e){ _msg('Failed to save: $e',err:true); }
    finally { setState(()=>_isSaving=false); }
  }

    @override Widget build(BuildContext ctx) => Scaffold(
    backgroundColor:const Color(0xFFF1F5F9),
    body:_isLoading?const Center(child:CircularProgressIndicator()):switch(_view){
      _ViewMode.list   => _scroll(child:_buildList()),
      _ViewMode.create => _scroll(child:_buildForm(isEdit:false)),
      _ViewMode.edit   => _scroll(child:_buildForm(isEdit:true)),
      _ViewMode.view   => _scroll(child:_buildDetail()),
      _ViewMode.delete => _scroll(child:_buildDelete()),
      _ViewMode.bulkUpload => _buildBulkUpload(),
    });

  Widget _buildBulkUpload() {
    return BulkUploadDialog(
      onComplete: () {
        _loadData();
        setState(() => _view = _ViewMode.list);
      },
      onCancel: () {
        setState(() => _view = _ViewMode.list);
      },
      title: 'Bulk Upload Users',
      entityName: 'Users',
      validateEndpoint: '/user-account/bulk-upload',
      uploadEndpoint: '/user-account/bulk-process',
      templateAssetPath: 'assets/User_Bulk_Upload_Template.xlsx',
      templateFileName: 'User_Bulk_Upload_Template.xlsx',
      templateSheetName: 'User Bulk Upload',
      programName: 'User_Account',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  LIST VIEW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildList() {
    final act=_activeCount; final ina=_inactiveCount;
    return StatefulBuilder(builder:(ctx,ls){
      int pg = _page;
      final tot=(_totalElements/_pageSize).ceil().clamp(1,9999);
      if(pg>=tot) pg=tot-1;
      if(pg<0) pg=0;
      final items=_users;
      final st=_totalElements==0?0:pg*_pageSize+1; final en=pg*_pageSize+items.length;

      void setPage(int newPg){
        setState(()=>_page=newPg);
        _fetchUsers();
      }

      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        _hdr(title:'User Accounts'),
        Wrap(spacing:10,runSpacing:10,children:[
          _stat('$_totalElements','Total Users',_kP,_kPL,_kPB,Icons.people_rounded,_kP),
          _stat('$act','Active',_kG,_kGL,_kGB,Icons.check_circle_outline_rounded,_kG),
          _stat('$ina','Inactive',_kR,_kRL,_kRB,Icons.block_rounded,_kR),
        ]),
        const SizedBox(height:16),
        Row(children:[
          const Spacer(),
          _SearchBox(onChanged:(v){
            if (_debounce?.isActive ?? false) _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              setState((){_search=v; _page=0;});
              _fetchUsers();
            });
          }),
          const SizedBox(width:10),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showFilterFields = !_showFilterFields;
                });
              },
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _showFilterFields ? const Color(0xFF2A55A5) : _kP,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    const Text(
                      'Filter',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    if (_orgFilter.isNotEmpty || _branchFilter.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_showFilterFields) ...[
            if (!_isAdmin || _orgs.length > 1) ...[
              const SizedBox(width:10),
              _OrgFilterButton(
                selectedOrgCode:_orgFilter.isEmpty?null:_orgFilter,
                organizations:_orgs,
                onChanged:(v){
                  setState((){_orgFilter=v??''; _branchFilter=''; _page=0;});
                  _fetchUsers();
                },
              ),
            ],
            if (_shouldShowBranchFilter) ...[
              const SizedBox(width:10),
              _BranchFilterButton(
                selectedBranchCode:_branchFilter.isEmpty?null:_branchFilter,
                selectedOrgCode:_orgFilter.isEmpty?null:_orgFilter,
                branches:_branches,
                onChanged:(v){
                  setState((){_branchFilter=v??''; _page=0;});
                  _fetchUsers();
                },
              ),
            ],
          ],
          if (widget.accessPrivileges?.canCreate ?? true) ...[
            const SizedBox(width:10),
            _btn('Upload Users',bg:_kP,fg:Colors.white,bd:_kP,ic:Icons.upload_file_rounded,onTap:()=>setState(()=>_view=_ViewMode.bulkUpload)),
            const SizedBox(width:10),
            _btn('New User',bg:_kP,fg:Colors.white,bd:_kP,ic:Icons.add_rounded,onTap:()=>_startView(_ViewMode.create)),
          ],
        ]),
        const SizedBox(height: 16),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Loading user accounts...')])),
          )
        else if (_isFetching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(height: 12),
                  Text('Loading user accounts...', style: TextStyle(fontSize: 12, color: _kText)),
                ],
              ),
            ),
          )
        else
          _card(child:LayoutBuilder(builder:(ctx,c){
            final cols=[20,17,10,13,13,13,14];

          Widget row(List<Widget> cells,List<int> flexes,{bool hd=false,bool even=false,bool hov=false}){
            Color bg; if(hd) bg=_kP; else if(hov) bg=_kPL; else if(even) bg=const Color(0xFFF0F5FD); else bg=Colors.white;
            return Container(decoration:BoxDecoration(color:bg,border:Border(bottom:BorderSide(color:hd?Colors.transparent:const Color(0xFFF1F5F9)))),
              child:Row(children:List.generate(flexes.length,(i)=>Expanded(flex:flexes[i],child:cells[i]))));
          }

          hcell(String t)=>Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:11),
            child:Center(child:Text(t,style:const TextStyle(fontSize:10.5,fontWeight:FontWeight.w700,color:Colors.white,letterSpacing:0.5))));

          dcell(Widget child,{EdgeInsets pad=const EdgeInsets.symmetric(horizontal:10,vertical:11)})=>
              Padding(padding:pad,child:Center(child:child));

          return Column(children:[
            row([hcell('ORGANIZATION'),hcell('BRANCH'),hcell('USER CODE'),hcell('FIRST NAME'),hcell('LAST NAME'),hcell('STATUS'),hcell('ACTIONS')],cols,hd:true),
            ...items.asMap().entries.map((e){
              final i=e.key; final r=e.value; final ev=i%2==1;
              return StatefulBuilder(builder:(_,rs){
                bool hov=false;
                return MouseRegion(cursor:SystemMouseCursors.click,
                  onEnter:(_)=>rs(()=>hov=true),onExit:(_)=>rs(()=>hov=false),
                  child:row([
                    dcell(Text(_orgDisp(r.orgCode),style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:_kP),maxLines:1,softWrap:false,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center)),
                    dcell(Text(_branchDisp(r.branchCode, r.orgCode),style:const TextStyle(fontSize:12.5,color:_kText),maxLines:1,softWrap:false,overflow:TextOverflow.ellipsis)),
                    dcell(Text(r.userCode.toString(),style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:_kP))),
                    dcell(Text(r.fName??'',style:const TextStyle(fontSize:12.5,color:_kText),overflow:TextOverflow.ellipsis)),
                    dcell(Text(r.lName??'',style:const TextStyle(fontSize:12.5,color:_kText),overflow:TextOverflow.ellipsis)),
                    dcell(_badge(r.isActive),pad:const EdgeInsets.symmetric(horizontal:8,vertical:9)),
                    dcell(Row(mainAxisSize:MainAxisSize.min,children:[
                      ...[
                        if (widget.accessPrivileges?.canView ?? true)
                          _rowBtn(Icons.visibility_outlined,const Color(0xFF475569),()=>_startView(_ViewMode.view,r)),
                        if (widget.accessPrivileges?.canEdit ?? true)
                          _rowBtn(Icons.edit_outlined,_kP,()=>_startView(_ViewMode.edit,r)),
                        if (widget.accessPrivileges?.canDelete ?? true)
                          _rowBtn(Icons.delete_outline_rounded,_kR,()=>_startView(_ViewMode.delete,r)),
                      ].map((btn) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: btn,
                      )),
                    ]),pad:const EdgeInsets.symmetric(horizontal:8,vertical:8)),
                  ],cols,even:ev,hov:hov));
              });
            }),
            Padding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:12),
              child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                Text(_totalElements == 0 ? 'No records found' : 'Showing $st–$en of $_totalElements records',style:const TextStyle(fontSize:11,color:Color(0xFF94A3B8))),
                Row(children:[
                  _pgBtn('‹ Prev',en:pg>0,onTap:()=>setPage(pg-1)),
                  const SizedBox(width:6),
                  _pgBtn('Next ›',en:pg<tot-1,onTap:()=>setPage(pg+1)),
                ]),
              ])),
          ]);
        })),
      ]);
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  FORM VIEW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildForm({required bool isEdit}) {
    // FIX: DOB max = 18 years ago, Registration Date max = today (no future)
    final dobMax=DateTime(DateTime.now().year-18,DateTime.now().month,DateTime.now().day);
    final regMax=DateTime.now(); // Block future dates

    return StatefulBuilder(builder:(ctx,sf){

      // ── Helper: clear error when field gets a value ──────────────────────
      void clearErr(String key) {
        if(_errors.containsKey(key)) { sf(()=>_errors.remove(key)); setState(()=>_errors.remove(key)); }
      }

      // ── Org code setter ──────────────────────────────────────────────────
      void _setOrgCode(String v) {
        _orgCodeCtrl.text = v;
        _branchCtrl.text = '';
        _roleCtrl.text = '';
        clearErr('org');
        final codePart = v.contains(' - ') ? v.split(' - ').first.trim() : v.trim();
        final orgCodeInt = int.tryParse(codePart) ?? 0;
        sf(() => _uploadOrgCode = orgCodeInt);
        setState(() => _uploadOrgCode = orgCodeInt);
        
        if (codePart.isNotEmpty) {
          AccessCodeService().getRolesByOrganization(codePart).then((roles) {
            if (mounted) {
              sf(() => _roles = roles);
              setState(() => _roles = roles);
            }
          }).catchError((e) {
            debugPrint('Error fetching roles: $e');
            if (mounted) {
              sf(() => _roles = []);
              setState(() => _roles = []);
            }
          });
        } else {
          sf(() => _roles = []);
          setState(() => _roles = []);
        }
      }

      // ── Branch setter: auto-populate country + callCode from branch ──────
      void _setBranchCode(String v) {
        _branchCtrl.text = v;
        clearErr('branch');
        if(v.isNotEmpty){
          final codePart = v.split(' - ').first.trim();
          final branchCode = int.tryParse(codePart);
          final selectedOrgCode = int.tryParse(_orgCodeCtrl.text.split(' - ').first.trim()) ?? 0;
          if(branchCode != null){
            Branch? foundBranch;
            try {
              foundBranch = _branches.firstWhere(
                (b) => b.branchCode == branchCode && b.orgCode == selectedOrgCode,
              );
            } catch(_){}
            if(foundBranch != null && foundBranch.country != null && foundBranch.country!.isNotEmpty){
              final ci = _findCountryFromApi(foundBranch.country!);
              if(ci != null){
                sf((){
                  _countryCode = ci.code;
                  _callCode = ci.dialCode;
                  _mobileLength = ci.mobileLength;
                  _mobileCtrl.text = ''; // reset mobile when country changes
                  _errors.remove('country');
                });
                setState((){
                  _countryCode = ci.code;
                  _callCode = ci.dialCode;
                  _mobileLength = ci.mobileLength;
                });
              }
            }
          }
        }
      }

      final selectedOrgCode = _orgCodeCtrl.text.isNotEmpty
        ? int.tryParse(_orgCodeCtrl.text.split(' - ').first.trim())
        : null;

      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        _hdr(
          title: isEdit ? 'Edit User Account' : 'Create User Account',
          actions: [
            _fBtn('Back', Icons.arrow_back_rounded, _kP, Colors.white, _kP, onTap: () => _startView(_ViewMode.list)),
          ],
        ),
        _card(child:Column(children:[
          // card header
          Container(padding:const EdgeInsets.symmetric(horizontal:22,vertical:16),
            decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:_kBorder))),
            child:Row(children:[
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(isEdit?'Edit User Details':'User Details',style:const TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:_kText)),
                const SizedBox(height:2),
                Text(isEdit?'Locked fields cannot be changed':'Fill all required fields marked with *',style:const TextStyle(fontSize:11,color:_kMuted)),
              ])),
              Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),
                decoration:BoxDecoration(color:isEdit?_kOBG:_kPL,borderRadius:BorderRadius.circular(20),border:Border.all(color:isEdit?_kOB:_kPB)),
                child:Text(isEdit?'EDIT MODE':'NEW RECORD',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:isEdit?_kOT:_kP))),
            ])),
          // banner
          if (isEdit)
            Container(margin:const EdgeInsets.fromLTRB(22,16,22,0),padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
              decoration:BoxDecoration(color:_kWarnBG,border:Border.all(color:_kWarnB),borderRadius:BorderRadius.circular(10)),
              child:Row(children:[
                Icon(Icons.lock_outline,size:15,color:_kWarnT),
                const SizedBox(width:8),
                Expanded(child:Text('Locked fields cannot be modified',
                  style:TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:_kWarnT))),
              ])),

          Padding(padding:const EdgeInsets.all(22),child:Column(children:[
            // FIX: increased childAspectRatio to 3.6 to prevent overflow of error text
            GridView.count(
              shrinkWrap:true,
              physics:const NeverScrollableScrollPhysics(),
              crossAxisCount:4,
              mainAxisSpacing:28,
              crossAxisSpacing:16,
              childAspectRatio:3.6,
              children:[
                _OrgDropdownField(
                  label:'Organization',
                  controller:_orgCodeCtrl,
                  organizations:_orgs,
                  readOnly:isEdit || (_isAdmin && _adminOrgLabel != null),
                  isRequired:true,
                  errorText:_errors['org'],
                  onChanged:(v) => sf(() => _setOrgCode(v)),
                ),
                _BranchDropdownField(
                  label:'Branch',
                  controller:_branchCtrl,
                  branches:_branches,
                  selectedOrgCode: selectedOrgCode,
                  readOnly: selectedOrgCode == null,
                  isRequired: true,
                  errorText:_errors['branch'],
                  onChanged:(v) => sf(() => _setBranchCode(v)),
                ),
                _FloatingLabelField(
                  label:'User Code',controller:_userCodeCtrl,icon:Icons.tag_rounded,hint:'Enter user code',
                  isRequired:true,readOnly:isEdit,showLock:isEdit,errorText:_errors['userCode'],
                  maxLength:10,
                  inputFormatters:[FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                  // FIX: clear error on type
                  onChanged:(v){ if(v.isNotEmpty) clearErr('userCode'); },
                ),
                _isAdmin 
                  ? _FloatingLabelField(
                      label:'Role',controller:_roleCtrl,icon:Icons.admin_panel_settings_outlined,
                      readOnly:true, showLock:true,
                    ) 
                  : _RoleDropdownField(
                      label:'Role',
                      controller:_roleCtrl,
                      roles: _roles,
                      readOnly: _orgCodeCtrl.text.isEmpty,
                      isRequired: true,
                      onChanged: (v) => sf((){ _roleCtrl.text = v; clearErr('role'); }),
                      errorText: _errors['role'],
                    ),
                _SimpleDropdownField(
                  label:'Title',controller:_titleCtrl,icon:Icons.person_outline_rounded,
                  items:const['Mr','Mrs','Ms'],hint:'Select title',isRequired:true,errorText:_errors['title'],
                  // FIX: clear error on select
                  onChanged:(v){ if(v.isNotEmpty) clearErr('title'); },
                ),
                _FloatingLabelField(
                  label:'First Name',controller:_firstCtrl,icon:Icons.person_rounded,hint:'Enter first name',
                  isRequired:true,errorText:_errors['firstName'],
                  maxLength:20,
                  inputFormatters: [_RejectingInputFormatter(RegExp(r'^[a-zA-Z\s]*$'), () {
                    sf(() => _errors['firstName'] = 'Only letters and spaces allowed');
                    setState(() {});
                  })],
                  onChanged:(v){ clearErr('firstName'); },
                ),
                _FloatingLabelField(
                  label:'Middle Name',controller:_midCtrl,icon:Icons.person_outline_rounded,hint:'Enter middle name',
                  maxLength:20,
                  errorText:_errors['midName'],
                  inputFormatters: [_RejectingInputFormatter(RegExp(r'^[a-zA-Z\s]*$'), () {
                    sf(() => _errors['midName'] = 'Only letters and spaces allowed');
                    setState(() {});
                  })],
                  onChanged:(v){ clearErr('midName'); },
                ),
                _FloatingLabelField(
                  label:'Last Name',controller:_lastCtrl,icon:Icons.person_rounded,hint:'Enter last name',
                  isRequired:true,errorText:_errors['lastName'],
                  maxLength:20,
                  inputFormatters: [_RejectingInputFormatter(RegExp(r'^[a-zA-Z\s]*$'), () {
                    sf(() => _errors['lastName'] = 'Only letters and spaces allowed');
                    setState(() {});
                  })],
                  onChanged:(v){ clearErr('lastName'); },
                ),
                _FloatingLabelField(
                  label:'Date of Birth',controller:_dobCtrl,icon:Icons.cake_rounded,hint:'Choose date',
                  isDatePicker:true,maxDate:dobMax,isRequired:true,errorText:_errors['dob'],readOnly:false,
                  onChanged:(v){ if(v.isNotEmpty) clearErr('dob'); },
                ),
                // FIX: Added 'Others' to gender
                _SimpleDropdownField(
                  label:'Gender',controller:_genderCtrl,icon:Icons.wc_rounded,
                  items:const['Male','Female','Others'],hint:'Select gender',isRequired:true,errorText:_errors['gender'],
                  onChanged:(v){ if(v.isNotEmpty) clearErr('gender'); },
                ),
                _CountryPickerField(
                  label:'Country',selectedCode:_countryCode,isRequired:true,errorText:_errors['country'],
                  countries:_resolvedCountries,
                  onChanged:(ci)=>sf((){
                    _countryCode=ci?.code;
                    _callCode=ci?.dialCode;
                    _mobileLength=ci?.mobileLength??10;
                    _mobileCtrl.text=''; // reset mobile on country change
                    _errors.remove('country');
                    setState((){
                      _countryCode=ci?.code;
                      _callCode=ci?.dialCode;
                      _mobileLength=ci?.mobileLength??10;
                    });
                  }),
                ),
                // FIX: Dynamic mobileLength passed to _MobileField
                _MobileField(
                  controller:_mobileCtrl,
                  callCode:_callCode,
                  errorText:_errors['mobile'],
                  mobileLength:_mobileLength,
                  onChanged: (v) {
                    if (v == 'invalid') {
                      sf(() => _errors['mobile'] = 'Only numbers allowed');
                      setState(() {});
                      return;
                    }
                    clearErr('mobile');
                  }
                ),
                _FloatingLabelField(
                  label:'Email',controller:_emailCtrl,icon:Icons.email_rounded,hint:'Enter email address',
                  isRequired:true,errorText:_errors['email'],
                  onChanged:(v){ if(v.isNotEmpty) clearErr('email'); },
                ),
                _UserToggle(
                  label:'Status',
                  icon:Icons.check_circle_outline_rounded,
                  isActive:_statusCtrl.text == 'Active',
                  trueLabel:'Active',
                  falseLabel:'Inactive',
                  activeColor:_kG,
                  onChanged:(v){
                    sf((){
                      _statusCtrl.text = v ? 'Active' : 'Inactive';
                      clearErr('status');
                    });
                    setState((){
                      _statusCtrl.text = v ? 'Active' : 'Inactive';
                      clearErr('status');
                    });
                  },
                  hasError:_errors['status'] != null,
                ),
                // FIX: maxDate = today to block future registration dates
                _FloatingLabelField(
                  label:'Registration Date',controller:_regDateCtrl,
                  icon:Icons.calendar_today_rounded,hint:'Choose date',
                  isDatePicker:true,
                  maxDate:regMax,   // ← blocks future dates
                  isRequired:true,errorText:_errors['regDate'],readOnly:false,
                  onChanged:(v){ if(v.isNotEmpty) clearErr('regDate'); },
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical:20),
              child: Divider(height:1,color:_kBorder),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children:[
                  Row(children:[
                    Container(width:28,height:28,
                      decoration:BoxDecoration(color:_kPL,borderRadius:BorderRadius.circular(7)),
                      child:const Icon(Icons.photo_camera_rounded,size:15,color:_kP)),
                    const SizedBox(width:10),
                    Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      const Text('Profile Picture',
                        style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:_kText)),
                      Text(
                        _errors['picture']!=null ? 'Profile picture is required' : 'Upload a photo for this user',
                        style:TextStyle(fontSize:10,color:_errors['picture']!=null?_kR:_kMuted)),
                    ]),
                    if(_errors['picture']!=null)...[
                      const SizedBox(width:8),
                      const Icon(Icons.error_outline_rounded,size:15,color:_kR),
                    ],
                  ]),
                  const SizedBox(height:14),
                  SizedBox(
                    width: 180,
                    child: _PictureUploadBox(
                      key: _pictureBoxKey,
                      orgCode: _uploadOrgCode,
                      initialPath: (_picturePath == '__pending__') ? null : _picturePath,
                      isEditMode: isEdit,
                      isRequired: true,
                      hasError: _errors['picture'] != null,
                      errorMsg: _errors['picture'],
                      onPending: (pending) {
                        setState(() {
                          _pendingPicture = pending;
                          if (pending == null) _picturePath = null;
                        });
                      },
                      onUploaded: (p) => sf(() {
                        setState(() { _picturePath = p; _errors.remove('picture'); });
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ])),
        ])),

        const SizedBox(height:20),
        Row(mainAxisAlignment:MainAxisAlignment.end,children:[
          _fBtn('Cancel',Icons.close_rounded,Colors.white,_kP,_kP,onTap:()=>_startView(_ViewMode.list)),
          const SizedBox(width:12),
          _fBtn(_isSaving?'Saving...':(isEdit?'Update':'Create'),Icons.save_rounded,_kP,Colors.white,_kP,onTap:_isSaving?null:_save),
        ]),
      ]);
    });
  }

  String _formatAuditDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
      final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final m = d.minute.toString().padLeft(2, '0');
      final p = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day.toString().padLeft(2,'0')} ${ms[d.month - 1]} ${d.year}, ${h.toString().padLeft(2,'0')}:$m $p';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatForDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final y = int.parse(parts[0]); final m = int.parse(parts[1]); final d = int.parse(parts[2]);
          const ms=['January','February','March','April','May','June','July','August','September','October','November','December'];
          return '${d.toString().padLeft(2,'0')}-${ms[m-1]}-$y';
        } else {
          final d = int.parse(parts[0]); final mo = parts[1]; final y = int.parse(parts[2]);
          const moMap={'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12};
          final mIndex = moMap[mo] ?? (moMap[mo.substring(0,3)] ?? 1);
          const ms=['January','February','March','April','May','June','July','August','September','October','November','December'];
          return '${d.toString().padLeft(2,'0')}-${ms[mIndex-1]}-$y';
        }
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatForBackend(String? displayStr) {
    if (displayStr == null || displayStr.isEmpty) return '';
    try {
      final parts = displayStr.split('-');
      if (parts.length == 3) {
        final d = int.parse(parts[0]); final mo = parts[1]; final y = int.parse(parts[2]);
        const moMap={'January':1,'February':2,'March':3,'April':4,'May':5,'June':6,'July':7,'August':8,'September':9,'October':10,'November':11,'December':12};
        final mIndex = moMap[mo] ?? 1;
        const ms=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        return '${d.toString().padLeft(2,'0')}-${ms[mIndex-1]}-$y';
      }
    } catch (_) {}
    return displayStr;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  DETAIL VIEW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDetail() {
    final u = _selected!;
    final fn = '${u.fName ?? ''} ${u.mName ?? ''} ${u.lName ?? ''}'.trim();
    final ci = u.country != null ? _findCountryFromApi(u.country!) : null;
    final cc = u.callCode?.isNotEmpty == true ? u.callCode : _findCountryFromApi(u.country ?? '')?.dialCode;

    ro(String lbl, String v, IconData ic, {bool lock = false, String? sub}) => _FloatingLabelField(
      label: lbl,
      controller: TextEditingController(text: v),
      icon: ic,
      readOnly: true,
      isRequired: false,
      showLock: false, // Ensure lock symbol does not show in view mode
      subtext: sub,
    );

    return _scroll(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hdr(
        title: 'User Account Details',
        actions: [
          _fBtn('Audit Details', Icons.history_rounded, Colors.white, _kP, _kP, onTap: () => AuditDetailsDialog.show(
            context,
            title: 'Audit Details',
            subtitle: 'User Account audit trail for ${u.userCode}',
            cuser: u.euser, cdate: _formatAuditDate(u.edate),
            euser: u.cuser, edate: _formatAuditDate(u.cdate),
            auser: u.auser, adate: _formatAuditDate(u.adate),
          )),
          const SizedBox(width: 8),
          _fBtn('Back', Icons.arrow_back_rounded, _kP, Colors.white, _kP, onTap: () => _startView(_ViewMode.list)),
        ],
      ),

      _card(child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEEF3FB), Colors.white],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(children: [
            _PictureViewWidget(orgCode: u.orgCode, picturePath: u.picture),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fn.isEmpty ? 'User Account' : fn, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kP)),
              const SizedBox(height: 2),
              Text('User Code: ${u.userCode} • Org: ${u.orgCode} • Created: ${u.regDate ?? '-'}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ])),
            _badge(u.isActive),
          ])),
        Padding(
          padding: const EdgeInsets.all(22),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 28,
            crossAxisSpacing: 16,
            childAspectRatio: 3.6,
            children: [
              ro('Organization', u.orgCode.toString(), Icons.apartment_rounded, lock: true, sub: () {
                final match = _orgs.where((o) => ((o['orgcode'] ?? o['orgCode'])?.toString() ?? '') == u.orgCode.toString()).toList();
                return match.isNotEmpty ? (match.first['orgName'] ?? match.first['name'] ?? '').toString() : '';
              }()),
              ro('Branch', u.branchCode.toString(), Icons.location_city_rounded, lock: true, sub: () {
                final match = _branches.where((b) => b.branchCode.toString() == u.branchCode.toString() && b.orgCode.toString() == u.orgCode.toString()).toList();
                return match.isNotEmpty ? match.first.branchName : '';
              }()),
              ro('User Code', u.userCode.toString(), Icons.tag_rounded, lock: true),
              ro('Role', u.roleType ?? '', Icons.admin_panel_settings_outlined, sub: () {
                final rt = u.roleType ?? '';
                if (rt.isEmpty) return '—';
                final match = _roles.where((r) => r.id?.toString() == rt).toList();
                return match.isNotEmpty ? match.first.accessName : rt;
              }()),
              ro('Title', u.title ?? '—', Icons.person_outline_rounded),
              ro('First Name', u.fName ?? '—', Icons.person_rounded),
              ro('Middle Name', u.mName ?? '—', Icons.person_outline_rounded),
              ro('Last Name', u.lName ?? '—', Icons.person_rounded),
              ro('Date of Birth', _formatForDisplay(u.dob) == '' ? '—' : _formatForDisplay(u.dob), Icons.cake_rounded),
              ro('Gender', u.gender == 'M' ? 'Male' : (u.gender == 'F' ? 'Female' : (u.gender == 'O' ? 'Others' : u.gender ?? '—')), Icons.wc_rounded),
              ro('Country', ci != null ? ci.name : (u.country ?? '—'), Icons.language_rounded),
              _MobileField(
                controller: TextEditingController(text: u.mobile),
                callCode: cc,
                mobileLength: ci?.mobileLength ?? 10,
                readOnly: true,
              ),
              ro('Email', u.emailId ?? '—', Icons.email_rounded),
              _UserToggle(
                label: 'Status',
                icon: Icons.check_circle_outline_rounded,
                isActive: u.isActive,
                trueLabel: 'Active',
                falseLabel: 'Inactive',
                activeColor: _kG,
                onChanged: (_) {},
                readOnly: true,
              ),
              ro('Registration Date', _formatForDisplay(u.regDate) == '' ? '—' : _formatForDisplay(u.regDate), Icons.calendar_today_rounded),
            ],
          ),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorder))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _fBtn('Back', Icons.arrow_back_rounded, _kP, Colors.white, _kP, onTap: () => _startView(_ViewMode.list)),
          ]),
        ),
      ])),
    ]));
  }


  // ──────────────────────────────────────────────────────────────────────────
  //  DELETE VIEW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDelete() {
    final u=_selected!;
    return StatefulBuilder(builder:(ctx,ls)=>_scroll(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      _hdr(title:'Delete User Account'),
      _card(child:Column(children:[
        Container(width:double.infinity,padding:const EdgeInsets.symmetric(vertical:16),color:_kRL,
          child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[
            Icon(Icons.delete_outline_rounded,size:20,color:_kR),SizedBox(width:8),
            Text('Delete Confirmation',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:_kR)),
          ])),
        Padding(padding:const EdgeInsets.all(22),child:Column(children:[
          const Text('Are you sure you want to delete this record? This action cannot be undone.',textAlign:TextAlign.center,style:TextStyle(fontSize:13,color:_kMuted)),
          const SizedBox(height:16),
          Container(width:double.infinity,padding:const EdgeInsets.all(16),
            decoration:BoxDecoration(color:Colors.white,border:Border.all(color:_kBorder),borderRadius:BorderRadius.circular(10)),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('RECORD TO BE DELETED',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Color(0xFF94A3B8),letterSpacing:0.8)),
              const SizedBox(height:10),
              _dr('Org Code:',u.orgCode.toString(),red:true),const SizedBox(height:6),
              _dr('User Code:',u.userCode.toString()),const SizedBox(height:6),
              _dr('First Name:',u.fName??''),const SizedBox(height:6),
              _dr('Last Name:',u.lName??''),const SizedBox(height:6),
              _dr('Email:',u.emailId??''),const SizedBox(height:6),
              _dr('Mobile:',u.mobile??''),
            ])),
          const SizedBox(height:12),
          GestureDetector(onTap:()=>ls(()=>setState(()=>_delConfirmed=!_delConfirmed)),
            child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),
              decoration:BoxDecoration(color:_kRL,border:Border.all(color:_kRB),borderRadius:BorderRadius.circular(10)),
              child:Row(children:[
                AnimatedContainer(duration:const Duration(milliseconds:150),width:18,height:18,
                  decoration:BoxDecoration(color:_delConfirmed?_kR:Colors.white,borderRadius:BorderRadius.circular(4),border:Border.all(color:_kR,width:1.5)),
                  child:_delConfirmed?const Icon(Icons.check_rounded,size:12,color:Colors.white):null),
                const SizedBox(width:10),
                const Expanded(child:Text('I understand this will permanently delete this record and all related data.',
                  style:TextStyle(fontSize:12,color:_kR,fontWeight:FontWeight.w500))),
              ]))),
        ])),
        Container(padding:const EdgeInsets.symmetric(horizontal:22,vertical:14),
          decoration:const BoxDecoration(border:Border(top:BorderSide(color:_kBorder))),
          child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[
            _fBtn('Cancel',Icons.close_rounded,Colors.white,_kP,_kP,onTap:()=>_startView(_ViewMode.list)),
            const SizedBox(width:10),
            _fBtn('Confirm Delete',Icons.delete_outline_rounded,
              _delConfirmed?_kR:Colors.white,_delConfirmed?Colors.white:const Color(0xFFCBD5E1),_delConfirmed?_kR:_kBorder,
              onTap:_delConfirmed&&!_isDeleting?()async{
                setState(()=>_isDeleting=true);
                try{
                  await _userSvc.deleteUser(u.orgCode,u.userCode);
                  OperationalLogService().logAction(programId: 'USER ACCOUNTS', action: 'D');
                  await _loadData();
                  _startView(_ViewMode.list);
                  _msg('User account deleted successfully!');
                }
                catch(e){ _msg('Failed to delete user account.',err:true); }
                finally{ setState(()=>_isDeleting=false); }
              }:null),
          ])),
      ])),
    ])));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  User Toggle Switch (Status Toggle Switch matching Branches Screen)
// ═════════════════════════════════════════════════════════════════════════════
class _UserToggle extends StatelessWidget {
  final String label; final IconData icon;
  final bool isActive; final String trueLabel; final String falseLabel;
  final Color activeColor; final ValueChanged<bool> onChanged; final bool hasError; final bool readOnly;

  const _UserToggle({
    required this.label, required this.icon,
    required this.isActive, required this.trueLabel, required this.falseLabel,
    required this.activeColor, required this.onChanged, this.hasError = false, this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bc = hasError ? _kR : _kP;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: readOnly ? _kSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bc, width: 1.5),
          ),
          child: Row(children: [
            Icon(icon, size: 14, color: bc),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isActive ? trueLabel : falseLabel,
                key: ValueKey(isActive),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isActive ? activeColor : _kMuted),
              ),
            ),
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: readOnly ? null : () => onChanged(!isActive),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34, height: 18, padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        Positioned(
          top: -8, left: 28,
          child: Container(
            color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text.rich(
              TextSpan(text: label, children: const [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ]),
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
                color: bc, letterSpacing: 0.2, decoration: TextDecoration.none),
            ),
          ),
        ),
      ]),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text('$label is required',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2)),
        ),
    ]);
  }
}

class _RejectingInputFormatter extends TextInputFormatter {
  final RegExp pattern;
  final VoidCallback onReject;

  _RejectingInputFormatter(this.pattern, this.onReject);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (pattern.hasMatch(newValue.text)) return newValue;
    onReject();
    return oldValue;
  }
}