import 'package:client/index.dart';
import 'package:flutter/material.dart';

class SearchWidget extends StatelessWidget {
  final TextEditingController textedit;
  final String hint;
  final Color color;
  final Function(String) function;

  const SearchWidget({
    super.key,
    required this.textedit,
    required this.hint,
    required this.color,
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white),
          color: color),
      child: TextField(
        onSubmitted: (query) {
          function(query); // Gọi hàm khi có thay đổi văn bản
        },
        controller: textedit,
        style: TextStyles.searchtext,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.all(10),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
