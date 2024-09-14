import 'package:flutter/material.dart';
import 'settings_page.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Feed'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildNewsItem(),
          _buildNewsItem(),
          // Add more news items as needed
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: 0, // Set to 0 for Feed
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on Feed page, no action needed
              break;
            case 1:
              // TODO: Implement navigation to Post page
              break;
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsPage()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildNewsItem() {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        children: [
          Image.asset(
            'images/image_placeholder.png', // Replace with actual image
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200, // Adjust height as needed
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'News Headline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'News content preview...',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  child: Text('Read more'),
                  onPressed: () {
                    // TODO: Add code to dynamically fetch more news content and display them on a news page
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
