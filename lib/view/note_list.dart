import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:rest_api/model/api_response.dart';
import 'package:rest_api/model/note_for_listing.dart';
import 'package:rest_api/services/note_service.dart';
import 'package:rest_api/view/note_delete.dart';
import 'package:rest_api/view/note_modify.dart';

class NoteList extends StatefulWidget {
  @override
  _NoteListState createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  NoteServices get service => GetIt.I<NoteServices>();
  APIResponse<List<NoteModel>> _apiResponse;
  bool _isLoading = false;

  @override
  void initState() {
    _fetchNote();
    super.initState();
  }

  _fetchNote() async {
    setState(() {
      _isLoading = true;
    });
    _apiResponse = await service.getNoteList();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('List of notes')),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => NoteModify()))
                .then((value) {
              _fetchNote();
            });
          },
          child: Icon(Icons.add),
        ),
        body: Builder(
          builder: (_) {
            if (_isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (_apiResponse.error) {
              return Center(child: Text(_apiResponse.errorMessage));
            }

            return ListView.separated(
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.green),
              itemBuilder: (_, index) {
                return Dismissible(
                  key: ValueKey(_apiResponse.data[index].noteID),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direction) {},
                  confirmDismiss: (direction) async {
                    final result = await showDialog(
                        context: context, builder: (_) => NoteDelete());
                    if (result) {
                      final result = await service
                          .deleteNote(_apiResponse.data[index].noteID);
                      var message;
                      if (result != null && result.data) {
                        message = 'The note was deleted successfully';
                      } else {
                        message = result.errorMessage ?? 'An error occurred';
                      }
                      showDialog(context: context, builder: (____) =>
                          AlertDialog(
                            title: Text("Done"),
                            content: Text(message),
                            actions: [
                              TextButton(onPressed: () {
                                Navigator.of(context).pop();
                              }, child: Text("Ok"))
                            ],
                          ));
                      return result?.data ?? false;
                    }
                    return result;
                  },
                  background: Container(
                    color: Colors.red,
                    padding: EdgeInsets.only(left: 16),
                    child: Align(
                      child: Icon(Icons.delete, color: Colors.white),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      _apiResponse.data[index].noteTitle,
                      style: TextStyle(color: Theme
                          .of(context)
                          .primaryColor),
                    ),
                    subtitle: Text(
                        'Last edited on ${formatDateTime(
                            _apiResponse.data[index].latestEditDateTime ??
                                _apiResponse.data[index].createDateTime)}'),
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                          builder: (_) =>
                              NoteModify(
                                  noteId: _apiResponse.data[index].noteID)))
                          .then((value) {
                        _fetchNote();
                      });
                    },
                  ),
                );
              },
              itemCount: _apiResponse.data.length,
            );
          },
        ));
  }
}

String formatDateTime(DateTime dateTime) {
  return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
}
