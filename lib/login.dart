import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login() {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username == 'admin' && password == '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prawidłowe dane logowania'))
        );
      // Navigator.pushReplacement(
      //   context, 
      //   MaterialPageRoute(builder: (context) => const MapPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nieprawidłowe dane logowania'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 70),
              const SizedBox(height: 30),
              const Text(
                'Logowanie',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Login',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person)
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  child: const Padding(
                    padding: EdgeInsets.all(15),
                    child: Text('Log in', style: TextStyle(fontSize: 18)))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}