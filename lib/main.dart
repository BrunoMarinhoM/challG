import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals/globals.dart';
import '../classes/Business.dart';
import '../assetsScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tractian Challenge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<ListOfBusiness?> business;

  @override
  void initState() {
    business = fetchBusiness();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff17192D),
        title: Image.asset("assets/logo.png"),
        centerTitle: true,
      ),
      body: Center(
          child: FutureBuilder(
              future: business,
              builder: (context, snap) {
                if (snap.hasError) {
                  throw Exception("${snap.error}");
                }
                if (snap.hasData && snap.data != null) {
                  final businessButtons = List<Widget>.generate(
                      snap.data!.length,
                      (index) => _buildMenuButton(snap.data!.getAt(index)));
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: businessButtons,
                  );
                }
                return const CircularProgressIndicator();
              })),
    );
  }

  _buildMenuButton(Business business) {
    var title = business.getName();
    return Container(
        width: MediaQuery.of(context).size.width,
        height: double.parse("100"),
        margin: const EdgeInsets.all(20),
        child: FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.centerLeft,
              backgroundColor: const Color(0xff2188FF),
            ),
            onPressed: () => {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AssetsScreen(
                            businessId: business.getId(),
                          )))
                },
            child: Row(children: [
              const Icon(Icons.business_rounded),
              Text(" $title Unit")
            ])));
  }

  Future<ListOfBusiness?> fetchBusiness() async {
    var client = http.Client();

    final http.Response response;
    try {
      response = await client.get(Uri.http(apiUri, "companies"));
    } catch (err) {
      return ListOfBusiness(list: [], length: 0);
    }

    if (response.statusCode != 200) {
      return null;
    }

    try {
      return ListOfBusiness.fromJson(response.body);
    } catch (err) {
      throw Exception(
          "There is something wrong with the api -> ${err.toString()}");
    }
  }
}
