import 'package:flutter/material.dart';

class SearchButton extends StatelessWidget {
  const SearchButton({
    Key? key,
    required this.text,
    required this.controller,
    required this.search,
  }) : super(key: key);
  final TextEditingController controller;
  final String text;
  final Function search;

  @override
  Widget build(context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10),
      margin: const EdgeInsets.only(bottom: 20, top: 20),
      height: 45,
      width: MediaQuery.of(context).size.width / 1.5,
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (string) => search(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: text,
                suffixIcon: IconButton(
                  onPressed: () {
                    controller.clear();
                    search();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
