import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course_model.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  CourseModel? _selectedCourse;
  UserModel? _user;

  CourseModel? get selectedCourse => _selectedCourse;
  UserModel? get user => _user;

  Future<void> loadUser() async {
    String id = "3ewI769MYNLYb1KHEanR"; // TODO: Receber ID como parâmetro.

    final doc = await _database.collection('users').doc(id).get();
    _user = await UserModel.fromMap(id: id, map: doc.data() ?? {});

    _selectedCourse = _user?.courses.first.course;

    notifyListeners();
  }
}