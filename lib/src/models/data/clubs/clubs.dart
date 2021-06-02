import "package:ramaz/models.dart";
import "package:ramaz/data.dart";
import "package:ramaz/services.dart";
import "../model.dart";

/// A model which handles all the club actions for users.
class Clubs extends Model{
  @override
  Future<void> init() async {
  }

  /// A function that gets all the clubs in the database.
  Future<void> getAllClubs() async => [
    for(final Map json in await Services.instance.database.clubs.getAll()){
      Club.fromjson(json)
    }
  ];

  /// Allows a user to register
  Future<void> registerForClub(Club club) async {
    Models.instance.user.data.registeredClubs.add(club.id);
    club.members.add(Models.instance.user.data.contactInfo);
    await Services.instance.database.clubs.register(
        club.id, Models.instance.user.data.contactInfo.toJson()
    );
  }

  ///Allows User to unregister from a club
  Future<void> unregisterFromClub(Club club) async {
    Models.instance.user.data.registeredClubs.remove(club.id);
    club.members.remove(Models.instance.user.data.contactInfo);
    await Services.instance.database.clubs.unregister(
        club.id, Models.instance.user.data.contactInfo.toJson()
    );
  }

  ///Adds the User's phone number to contactInfo.phoneNumber
  Future<void> addPhoneNumber(String number) async {
    Models.instance.user.data.contactInfo.phoneNumber=number;
  }
}
