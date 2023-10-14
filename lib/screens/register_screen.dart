/*
 ********************************************************************************

    _____/\\\\\\\\\_____/\\\\\\\\\\\\\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\\\_
    ___/\\\\\\\\\\\\\__\///////\\\/////__\/////\\\///__\/\\\///////////__
    __/\\\/////////\\\_______\/\\\___________\/\\\_____\/\\\_____________
    _\/\\\_______\/\\\_______\/\\\___________\/\\\_____\/\\\\\\\\\\\_____
    _\/\\\\\\\\\\\\\\\_______\/\\\___________\/\\\_____\/\\\///////______
    _\/\\\/////////\\\_______\/\\\___________\/\\\_____\/\\\_____________
    _\/\\\_______\/\\\_______\/\\\___________\/\\\_____\/\\\_____________
    _\/\\\_______\/\\\_______\/\\\________/\\\\\\\\\\\_\/\\\_____________
    _\///________\///________\///________\///////////__\///______________

    Created by Muhammad Atif on 10/11/2023.
    Portfolio https://atifnoori.web.app.

 ********************************************************************************
 */

import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_detector/model/face_features.dart';
import 'package:face_detector/model/user_model.dart';
import 'package:face_detector/services/extract_features.dart';
import 'package:face_detector/widgets/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:uuid/uuid.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  String? _image;
  FaceFeatures? _faceFeatures;

  bool isRegistering = false;
  final _formFieldKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Register User"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CameraView(
              onImage: (image) {
                setState(() {
                  _image = base64Encode(image);
                });
              },
              onInputImage: (inputImage) async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                        // color: accentColor,
                        ),
                  ),
                );
                await extractFaceFeatures(inputImage, _faceDetector)
                    .then((faceFeatures) {
                  setState(() {
                    _faceFeatures = faceFeatures;
                  });
                  Navigator.of(context).pop();
                });
              },
            ),
            const SizedBox(
              height: 16,
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formFieldKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your name";
                          } else {
                            return null;
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Enter user name',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        child: const Text("Start Registering"),
                        onPressed: () {
                          if (_faceFeatures != null) {
                            if (_formFieldKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              );

                              String userId = const Uuid().v1();
                              UserModel user = UserModel(
                                id: userId,
                                name: _nameController.text.trim(),
                                image: _image,
                                registeredOn: Timestamp.now(),
                                faceFeatures: _faceFeatures,
                              );

                              FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(userId)
                                  .set(user.toJson())
                                  .catchError((e) {
                                log("Registration Error: $e");
                                Navigator.of(context).pop();
                                showToast('Registration Failed! Try Again.');
                              }).whenComplete(() {
                                Navigator.of(context).pop();
                                showToast('Registered successfully');
                                Future.delayed(const Duration(seconds: 1), () {
                                  Navigator.pop(context);
                                });
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showToast(msg){
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
    );
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }
}
