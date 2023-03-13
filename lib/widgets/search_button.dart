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
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: TextField(
        controller: controller,
        onSubmitted: (string) => search(),
        decoration: InputDecoration(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width / 1.2,
          ),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          prefixIcon: const Icon(Icons.search),
          labelText: text,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  controller.clear();
                  search();
                },
                icon: const Icon(Icons.clear),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
