

import 'package:flutter/material.dart';

import '../Models/Cours.dart';
import '../Pages/CourseActions.dart';
import '../Pages/CoursesCheckList.dart';

class CoursItem extends StatelessWidget {
  final Cours cours;
  final int userID;

  const CoursItem({required this.cours,required this.userID});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0), // padding sur Y
      color: Colors.grey.shade200, // couleur de fond personnalisée
      child: ListTile(
        title: Text("${cours.jour} - ${cours.heure.substring(0,5)} - ${cours.dojo?.nom}",style: TextStyle(color: Colors.blue,fontWeight: FontWeight.bold),),
        //subtitle: Text("Âge : ${cours.categorieAge}"),
        onTap: (){
          print("${cours.id} ${cours.jour} ${cours.heure.substring(0,5)}");
          Navigator.push(context,
            MaterialPageRoute(builder: (context)=> CourseActionsPage( userId: userID, courseId: cours.id,))
          );
          },
      ),
    );
  }
}
