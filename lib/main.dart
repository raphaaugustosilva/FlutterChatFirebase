import 'package:chat_firebase/ui/paginaPrincipal.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  runApp(PaginaPrincipal());

  //DocumentSnapshot snapshot = await Firestore.instance.collection("teste").document("teste").get();
  //print(snapshot.data);

  Firestore.instance.collection("mensagens").snapshots().listen((snapshot) {
    for (DocumentSnapshot doc in snapshot.documents) {
      print(doc.data);
    }
  });

  // Firestore.instance
  //     .collection("teste")
  //     .document("teste")
  //     .setData({"teste": "teste"});

  
}
