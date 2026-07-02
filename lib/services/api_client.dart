// ignore_for_file: unnecessary_library_name
library api_client;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:assignment/core/config/api_config.dart';
import 'package:assignment/models/auth_session.dart';
import 'package:assignment/models/destination.dart';

part 'api/api_models.dart';
part 'api/api_client_impl.dart';
