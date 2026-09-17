import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class ClassEvaluationScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final SchoolClass schoolClass;
  final List<Student> students;
  final LocalStore store;
  const ClassEvaluationScreen({super.key, required this.config, required this.snapshot, required this.schoolClass, required this.students, required this.store});
  @override State<ClassEvaluationScreen> createState() => _ClassEvaluationScreenState();
}

class _ClassEvaluationScreenState extends State<ClassEvaluationScreen> {
  DateTime date = DateTime.now();
  String subject = 'Arabe';
  final title = TextEditingController();
  final Map<String, TextEditingController> scores = {};
  final Map<String, String> scoreStatus = {};

  String _date(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String _keyForSubject() => {'Coran':'quran','Arabe':'arabic','Aqida':'aqida','Fiqh':'fiqh','Sira':'sira'}[subject] ?? 'arabic';

  Future<void> _save() async {
    if (title.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indiquer le nom du contrôle.'))); return; }
    final deviceId = await widget.store.getOrCreateDeviceId();
    var count = 0;
    for (final s in widget.students) {
      final st = scoreStatus[s.id] ?? '';
      final txt = scores[s.id]?.text.trim().replaceAll(',', '.') ?? '';
      final value = double.tryParse(txt);
      if (st.isEmpty && value == null) continue;
      if (value != null && (value < 0 || value > widget.snapshot.evaluationMax)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note invalide pour ${s.displayName}.'))); return;
      }
      final payload = <String,dynamic>{
        'date': _date(date),
        'controlTitle': title.text.trim(),
        'subject': subject,
        if (st.isNotEmpty) 'scoreStatus': st,
        if (value != null) _keyForSubject(): value,
      };
      await widget.store.enqueue(TeacherEvent.create(type:'evaluation', teacher:widget.config.teacher, studentId:s.id, classId:widget.schoolClass.id, deviceId:deviceId, payload:payload));
      count++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count note(s)/statut(s) enregistré(s). Elles devront être validées par le Principal.')));
    Navigator.pop(context, true);
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Contrôle — ${widget.schoolClass.name}')),
    body: SafeArea(child: Column(children:[
      Padding(padding: const EdgeInsets.all(12), child: Column(children:[
        TextField(controller:title, decoration: const InputDecoration(labelText:'Nom du contrôle')),
        const SizedBox(height:8),
        Row(children:[
          Expanded(child: DropdownButtonFormField<String>(value:subject, decoration: const InputDecoration(labelText:'Matière'), items: const ['Coran','Arabe','Aqida','Fiqh','Sira'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged:(v)=>setState(()=>subject=v??'Arabe'))),
          const SizedBox(width:8),
          OutlinedButton.icon(onPressed:() async { final d=await showDatePicker(context:context, initialDate:date, firstDate:DateTime(DateTime.now().year-1), lastDate:DateTime(DateTime.now().year+1)); if(d!=null)setState(()=>date=d);}, icon:const Icon(Icons.calendar_month), label:Text(_date(date))),
        ]),
      ])),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(12,0,12,12), itemCount:widget.students.length, separatorBuilder:(_,__)=>const Divider(height:1), itemBuilder:(context,i){
        final s=widget.students[i];
        final c=scores.putIfAbsent(s.id,()=>TextEditingController());
        return Row(children:[
          Expanded(flex:3, child:Text(s.displayName, style:const TextStyle(fontWeight:FontWeight.w600))),
          const SizedBox(width:8),
          SizedBox(width:86, child:TextField(controller:c, keyboardType:const TextInputType.numberWithOptions(decimal:true), decoration:InputDecoration(labelText:'/${widget.snapshot.evaluationMax.toStringAsFixed(0)}'))),
          const SizedBox(width:8),
          SizedBox(width:120, child:DropdownButtonFormField<String>(value:(scoreStatus[s.id]??'').isEmpty?null:scoreStatus[s.id], hint:const Text('Statut'), items:const ['Absent','Dispensé','Non noté'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged:(v)=>setState(()=>scoreStatus[s.id]=v??''))),
        ]);
      })),
      Padding(padding:EdgeInsets.fromLTRB(12,8,12,16+MediaQuery.of(context).padding.bottom), child:SizedBox(width:double.infinity, child:FilledButton.icon(onPressed:_save, icon:const Icon(Icons.save_outlined), label:const Text('Enregistrer les notes')))),
    ])),
  );
}
