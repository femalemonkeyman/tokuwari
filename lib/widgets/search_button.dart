import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 8),
      sliver: SliverAppBar(
        floating: true,
        flexibleSpace: SearchBar(
          controller: controller,
          elevation: const WidgetStatePropertyAll<double>(0),
          shape: const WidgetStatePropertyAll(BeveledRectangleBorder()),
          onSubmitted: (string) => search(),
          onTapOutside:
              (event) => FocusManager.instance.primaryFocus!.unfocus(),
          leading: const Icon(Icons.search),
          hintText: text,
          trailing: [
            Visibility(
              visible: FocusManager.instance.primaryFocus?.hasFocus ?? false,
              child: IconButton(
                onPressed: () {
                  controller.clear();
                  search();
                },
                icon: const Icon(Icons.clear),
              ),
            ),
            IconButton(
              onPressed: () => context.pushNamed('settings'),
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ),
    );
  }
}
