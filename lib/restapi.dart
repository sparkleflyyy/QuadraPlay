// ignore_for_file: prefer_interpolation_to_compose_strings, non_constant_identifier_names

import 'package:http/http.dart' as http;

class DataService {
   Future insertUsers(String appid, String user_id, String name, String email, String password, String role, String createdat) async {
      String uri = 'https://api.247go.app/v5/insert/';

      try {
         final response = await http.post(Uri.parse(uri), body: {
            'token': '690de4f3fcee2015d33ec864',
            'project': 'sewa_ps',
            'collection': 'users',
            'appid': appid,
            'user_id': user_id,
            'name': name,
            'email': email,
            'password': password,
            'role': role,
            'createdat': createdat
         });

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future insertPsItems(String appid, String ps_id, String nama, String kategori, String deskripsi, String harga_perhari, String stok, String foto_url, String createdat) async {
      String uri = 'https://api.247go.app/v5/insert/';

      try {
         final response = await http.post(Uri.parse(uri), body: {
            'token': '690de4f3fcee2015d33ec864',
            'project': 'sewa_ps',
            'collection': 'ps_items',
            'appid': appid,
            'ps_id': ps_id,
            'nama': nama,
            'kategori': kategori,
            'deskripsi': deskripsi,
            'harga_perhari': harga_perhari,
            'stok': stok,
            'foto_url': foto_url,
            'createdat': createdat
         });

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future insertReservasi(String appid, String reservasi_id, String user_id, String ps_id, String jumlah_hari, String jumlah_unit, String tgl_mulai, String tgl_selesai, String alamat, String no_wa, String foto_ktp, String total_harga, String status, String createdat) async {
      String uri = 'https://api.247go.app/v5/insert/';

      try {
         final response = await http.post(Uri.parse(uri), body: {
            'token': '690de4f3fcee2015d33ec864',
            'project': 'sewa_ps',
            'collection': 'reservasi',
            'appid': appid,
            'reservasi_id': reservasi_id,
            'user_id': user_id,
            'ps_id': ps_id,
            'jumlah_hari': jumlah_hari,
            'jumlah_unit': jumlah_unit,
            'tgl_mulai': tgl_mulai,
            'tgl_selesai': tgl_selesai,
            'alamat': alamat,
            'no_wa': no_wa,
            'foto_ktp': foto_ktp,
            'total_harga': total_harga,
            'status': status,
            'createdat': createdat
         });

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future insertPayments(String appid, String payment_id, String reservasi_id, String user_id, String total_bayar, String metode_pembayaran, String bukti_pembayaran, String status, String createdat) async {
      String uri = 'https://api.247go.app/v5/insert/';

      try {
         final response = await http.post(Uri.parse(uri), body: {
            'token': '690de4f3fcee2015d33ec864',
            'project': 'sewa_ps',
            'collection': 'payments',
            'appid': appid,
            'payment_id': payment_id,
            'reservasi_id': reservasi_id,
            'user_id': user_id,
            'total_bayar': total_bayar,
            'metode_pembayaran': metode_pembayaran,
            'bukti_pembayaran': bukti_pembayaran,
            'status': status,
            'createdat': createdat
         });

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future insertAdminLogs(String appid, ) async {
      String uri = 'https://api.247go.app/v5/insert/';

      try {
         final response = await http.post(Uri.parse(uri), body: {
            'token': '690de4f3fcee2015d33ec864',
            'project': 'sewa_ps',
            'collection': 'admin_logs',
            'appid': appid,
         });

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectAll(String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/select_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectId(String token, String project, String collection, String appid, String id) async {
      String uri = 'https://api.247go.app/v5/select_id/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/id/' + id;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
      String uri = 'https://api.247go.app/v5/select_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
      String uri = 'https://api.247go.app/v5/select_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
      String uri = 'https://api.247go.app/v5/select_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
      String uri = 'https://api.247go.app/v5/select_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
      String uri = 'https://api.247go.app/v5/select_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future removeAll(String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/remove_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeId(String token, String project, String collection, String appid, String id) async {
      String uri = 'https://api.247go.app/v5/remove_id/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/id/' + id;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
      // Gunakan URL dengan parameters seperti endpoint lain yang berhasil
      String uri = 'https://api.247go.app/v5/remove_where/token/$token/project/$project/collection/$collection/appid/$appid/where_field/$where_field/where_value/$where_value';

      try {
         print('DEBUG removeWhere: where_field=$where_field, where_value=$where_value, collection=$collection');
         print('DEBUG removeWhere URI: $uri');
         
         // Coba GET method karena DELETE sering bermasalah dengan CORS
         final response = await http.get(Uri.parse(uri));
         
         print('DEBUG removeWhere response: ${response.statusCode} - ${response.body}');

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         print('DEBUG removeWhere error: $e');
         return false;
      }
   }

   Future removeOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
      String uri = 'https://api.247go.app/v5/remove_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
      String uri = 'https://api.247go.app/v5/remove_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
      String uri = 'https://api.247go.app/v5/remove_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
      String uri = 'https://api.247go.app/v5/remove_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future updateAll(String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_all/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateId(String update_field, String update_value, String token, String project, String collection, String appid, String id) async {
      String uri = 'https://api.247go.app/v5/update_id/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid,
             'id': id
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateWhere(String where_field, String where_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_where/';

      try {
         print('DEBUG updateWhere: where_field=$where_field, where_value=$where_value, update_field=$update_field, update_value=$update_value');
         // Try POST instead of PUT - some APIs require POST for updates
         final response = await http.post(Uri.parse(uri),body: {
             'where_field': where_field,
             'where_value': where_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         print('DEBUG updateWhere response: statusCode=${response.statusCode}, body=${response.body}');
         
         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         print('DEBUG updateWhere error: $e');
         return false;
      }
   }

   Future updateOrWhere(String or_where_field, String or_where_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_or_where/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'or_where_field': or_where_field,
             'or_where_value': or_where_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateWhereLike(String wlike_field, String wlike_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_where_like/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'wlike_field': wlike_field,
             'wlike_value': wlike_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateWhereIn(String win_field, String win_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_where_in/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'win_field': win_field,
             'win_value': win_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateWhereNotIn(String wnotin_field, String wnotin_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_where_not_in/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'wnotin_field': wnotin_field,
             'wnotin_value': wnotin_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future firstAll(String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/first_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
      String uri = 'https://api.247go.app/v5/first_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
      String uri = 'https://api.247go.app/v5/first_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
      String uri = 'https://api.247go.app/v5/first_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
      String uri = 'https://api.247go.app/v5/first_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
      String uri = 'https://api.247go.app/v5/first_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future lastAll(String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/last_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future lastWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
      String uri = 'https://api.247go.app/v5/last_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future lastOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
      String uri = 'https://api.247go.app/v5/last_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future lastWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
      String uri = 'https://api.247go.app/v5/last_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future lastWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
      String uri = 'https://api.247go.app/v5/last_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future lastWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
      String uri = 'https://api.247go.app/v5/last_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future randomAll(String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/random_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future randomWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
      String uri = 'https://api.247go.app/v5/random_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future randomOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
      String uri = 'https://api.247go.app/v5/random_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future randomWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
      String uri = 'https://api.247go.app/v5/random_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future randomWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
      String uri = 'https://api.247go.app/v5/random_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future randomWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
      String uri = 'https://api.247go.app/v5/random_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }
}