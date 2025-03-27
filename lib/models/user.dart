class UserApp {
  UserApp(this.nome, this.cognome, this.email, this.uid, this.palestre,
      this.codice, this.firstAccess);

  String uid;
  String nome;
  String cognome;
  String email;
  List<dynamic> palestre;
  String codice;
  bool firstAccess;
  String? imageURL;
}
