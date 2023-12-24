import 'package:flutter/material.dart';

class SearchButton extends StatelessWidget {
  const SearchButton({
    super.key,
    required this.text,
    required this.controller,
    required this.search,
  });
  final TextEditingController controller;
  final String text;
  final Function search;

  @override
  Widget build(context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Card(
          elevation: 5,
          shape: const StadiumBorder(),
          child: TextField(
            controller: controller,
            onSubmitted: (string) => search(),
            decoration: InputDecoration(
              border: InputBorder.none,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width / 1.2,
              ),
              prefixIcon: const Icon(Icons.search),
              hintText: text,
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
        ),
      ),
    );
  }
}
