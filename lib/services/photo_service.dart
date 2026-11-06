import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentz/services/user_profile_service.dart';

class PhotoService {

  Future<bool> pickAndSave() async{
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (file == null) return false;

    final bytes = await file.readAsBytes();
    await UserProfileService().update(uid, {'photoBase64': base64Encode(bytes),});
    return true;
  }
}