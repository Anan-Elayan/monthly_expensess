class Record {
  String desc;
  double amount;
  String date; // YYYY-MM-DD

  Record({required this.desc, required this.amount, required this.date});

  factory Record.fromJson(Map<String, dynamic> j) =>
      Record(desc: j['desc'], amount: j['amount'], date: j['date']);

  Map<String, dynamic> toJson() =>
      {'desc': desc, 'amount': amount, 'date': date};
}
