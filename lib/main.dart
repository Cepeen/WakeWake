import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WakeWake());
}

class WakeWake extends StatelessWidget {
  const WakeWake({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake! Wake!',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(title: 'Wake! Wake!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int port = 9;
  String macAddress = '';
  String ipAddress = '';

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('macAddress', macAddress);
    prefs.setString('ipAddress', ipAddress);
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      macAddress = (prefs.getString('macAddress') ?? '');
      ipAddress = (prefs.getString('ipAddress') ?? '');
    });
  }

  void _wakewake() {
    sendMagicPacket(macAddress, ipAddress); //target mac
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20.0),
          child: MacAddressTextField(
            onChanged: (value) {
              setState(() {
                macAddress = value;
              });
            },
            macAddress: macAddress,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20.0),
          child: IPAddressTextField(
            onChanged: (value) {
              setState(() {
                ipAddress = value;
              });
            },
            ipAddress: ipAddress,
          ),
        ),
        ElevatedButton(
          onPressed: _wakewake,
          child: const Text('Wake! Wake!'),
        ),
        ElevatedButton(
          onPressed: savePreferences,
          child: const Text('Save'),
        )
      ]),
    );
  }
}

void sendMagicPacket(String macAddress, String ipAddress) {
  final List<int> macBytes = macAddress.split(':').map((e) => int.parse(e, radix: 16)).toList();
  final List<int> packet = [];

  // Add 6 bytes with a value of 0xFF as the packet's initial part
  for (int i = 0; i < 6; i++) {
    packet.add(0xFF);
  }

  // Repeat the MAC address in byte form 16 times
  for (int i = 0; i < 16; i++) {
    packet.addAll(macBytes);
  }

  // Create a UDP socket and send the packet to the broadcast address
  RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
    socket.send(packet, InternetAddress(ipAddress), 9);
    socket.close();
  });
}

class IPAddressTextField extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final String ipAddress;

  const IPAddressTextField({Key? key, this.onChanged, required this.ipAddress}) : super(key: key);

  @override
  State<IPAddressTextField> createState() => _IPAddressTextFieldState();
}

class _IPAddressTextFieldState extends State<IPAddressTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: widget.onChanged,
      controller: TextEditingController.fromValue(
        TextEditingValue(
            text: widget.ipAddress,
            selection: TextSelection(
              baseOffset: widget.ipAddress.length,
              extentOffset: widget.ipAddress.length,
            )),
      ),
      decoration: const InputDecoration(
        labelText: 'IP Address',
      ),
    );
  }
}

class MacAddressTextField extends StatefulWidget {
  const MacAddressTextField({Key? key, required this.onChanged, required this.macAddress})
      : super(key: key);

  final ValueChanged<String> onChanged;
  final String macAddress;

  @override
  State<MacAddressTextField> createState() => _MacAddressTextFieldState();
}

class _MacAddressTextFieldState extends State<MacAddressTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: widget.onChanged,
      controller: TextEditingController.fromValue(
        TextEditingValue(
            text: widget.macAddress,
            selection: TextSelection(
              baseOffset: widget.macAddress.length,
              extentOffset: widget.macAddress.length,
            )),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-fA-F0-9-]')),
        _MacAddressInputFormatter(),
      ],
      decoration: const InputDecoration(
        labelText: 'MAC Address',
      ),
    );
  }
}

//TO DO - fix textfield cursor position issue
class _MacAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formattedText = formatMacAddress(newValue.text);
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// Getting MAC and checking if the format is correct
String formatMacAddress(String input) {
  // Remove any existing ":" characters from the input
  final sanitizedInput = input.replaceAll(":", "");

  // Ensure the input length is valid for a MAC address
  if (sanitizedInput.length != 12) {
    // Invalid input length
    return input;
  }

  // Split the input into pairs of symbols
  final pairs = <String>[];
  for (var i = 0; i < sanitizedInput.length; i += 2) {
    pairs.add(sanitizedInput.substring(i, i + 2));
  }

  // Join the pairs with ":"
  final formattedMacAddress = pairs.join(":");

  return formattedMacAddress;
}
