import 'package:flutter/material.dart';

class MaterialLocalizationsFallback
    extends LocalizationsDelegate<MaterialLocalizations> {
  const MaterialLocalizationsFallback();

  @override
  bool isSupported(Locale locale) => {'en', 'so'}.contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) => false;
}
