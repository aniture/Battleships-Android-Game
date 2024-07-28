import 'package:flutter/material.dart';
import 'package:battleships/utils/httpservice.dart';
import 'package:battleships/views/GameList.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true; // Toggle between Login & Registration

  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  HttpService httpService = HttpService();

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _login() async {
    int resp = await httpService.loginUser(_username, _password, context);
    if (resp == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GameListPage(username: _username)),
      );
    } else {
      // Optionally handle the login failure (e.g., show an error message)
      _showLoginError();
    }
  }

  void _showLoginError() {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please check your credentials and try again.'))
    );
  }

  void _register() {
    httpService
        .registerUser(_username, _password, context)
        .then((response) {
      if (response['statusCode'] == 200) {
        httpService.showAlertDialog(context, 'Registration Successful', 'You can now login');
        _toggleForm(); // Switch back to login after successful registration
      } else {
        httpService.showAlertDialog(context, 'Registration Failed', response['message']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register'),
          backgroundColor: _isLogin ? Colors.deepOrangeAccent : Colors.deepOrangeAccent),
      body: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                onSaved: (value) => _username = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (value) => _password = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    if (_isLogin) {
                      _login();
                    } else {
                      _register();
                    }
                  }
                },
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: _toggleForm,
                child: Text(_isLogin ? 'Create New Account' : 'Have an Account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
