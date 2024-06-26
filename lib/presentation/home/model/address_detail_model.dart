class Place {
  String? streetNumber;
  String? street;
  String? city;
  String? zipCode;
  String? state;
  String? country;

  Place(
      {this.streetNumber,
      this.street,
      this.city,
      this.zipCode,
      this.state,
      this.country});

  @override
  String toString() {
    return 'Place(streetNumber: $streetNumber, street: $street, city: $city, zipCode: $zipCode)';
  }
}

class Suggestion {
  final String placeId;
  final String description;

  Suggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}
