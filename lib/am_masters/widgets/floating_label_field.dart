import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_calendar_dialog.dart';

const _kP     = Color(0xFF3D6EBE);
const _kR     = Color(0xFFDC2626);
const _kText   = Color(0xFF1E293B);
const _kMuted  = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kSurface = Color(0xFFF8FAFC);

class FloatingLabelField extends StatefulWidget {
  final String label; final TextEditingController controller; final IconData icon;
  final String hint; final bool readOnly; final bool isRequired; final String? errorText;
  final bool isDatePicker; final DateTime? maxDate; final DateTime? minDate; final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool showLock;
  final String? subtext;

  const FloatingLabelField({
    super.key,
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

  @override State<FloatingLabelField> createState() => _FloatingLabelFieldState();
}

class _FloatingLabelFieldState extends State<FloatingLabelField> with SingleTickerProviderStateMixin {
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

  @override void didUpdateWidget(FloatingLabelField o) {
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
        hintText: _focused ? widget.hint : '',
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
