import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals/globals.dart';
import '../classes/Business.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});
  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  late Future<ListOfBusiness?> business;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xffffffff),
            )),
        backgroundColor: const Color(0xff17192D),
        title: const Text(
          "Assets",
          style: TextStyle(color: Color(0xffffffff)),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  height: 40,
                  child: SearchBar(
                    elevation: MaterialStateProperty.all<double>(0),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero)),
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xffEAEFF3)),
                    padding: MaterialStateProperty.all(
                        const EdgeInsets.only(left: 20)),
                    leading: const Icon(Icons.search_rounded),
                    hintText: "Buscar Ativo ou Local",
                  )),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: underSearchBarButtonStyle,
                        child: Row(children: [
                          Image.asset("assets/energy_icon.png"),
                          const Text(" Sensor de Energia"),
                        ]),
                      )),
                  const SizedBox(width: 10),
                  OutlinedButton(
                      onPressed: () {},
                      style: underSearchBarButtonStyle,
                      child: Row(
                        children: [
                          Image.asset("assets/alert_icon.png"),
                          const Text(" Sensor de Energia"),
                        ],
                      ))
                ],
              ),
            ]),
          ),
          const Divider(
            height: 0.2,
            thickness: 2,
          )
        ],
      ),
    );
  }
}
