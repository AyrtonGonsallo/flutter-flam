

import 'package:flutter/material.dart';

import '../Models/Cours.dart';

class EmptyView extends StatelessWidget {


  const EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("aucun"),
      subtitle: Text("aucun"),
    );
  }
}
