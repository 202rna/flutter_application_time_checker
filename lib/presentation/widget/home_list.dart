import 'package:flutter/material.dart';

class ListItem {
  final String id;
  final String name;

  const ListItem({
    required this.id,
    required this.name,
  });
}

class SportyList extends StatelessWidget {
  final List<ListItem> items;
  final Function(ListItem)? onItemTap;
  final Function(String)? onDelete;

  const SportyList({
    super.key,
    required this.items,
    this.onItemTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          ...items.map((item) {
            return InkWell(
              onTap: () => onItemTap?.call(item),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 16.0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(color: Color.fromARGB(255, 216, 129, 129)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10.0,
                      height: 10.0, // w-8 h-8
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange,
                            Color.fromARGB(255, 111, 17, 233)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0), // space-x-3

                    // Контент (имя)
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.black87, // text-gray-900
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDelete?.call(item.id),
                      //tooltip: 'Удалить запись',
                    ),
                  ],
                ),
              ),
            );
          }),
          Container(
            height: 4.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.red, Colors.purple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
