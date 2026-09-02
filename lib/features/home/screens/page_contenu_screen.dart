import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/page_providers.dart';

/// Écran générique de consultation d'une page de contenu CMS publiée
/// (Conditions générales, Avis de confidentialité...) — le contenu (HTML
/// produit par l'éditeur riche du panel d'administration) est celui déjà
/// défini côté back-end (table `pages`), jamais rédigé côté mobile.
class PageContenuScreen extends ConsumerWidget {
  /// Valeur de `type_page` côté back-end (`CGU`, `POLITIQUE_CONFIDENTIALITE`...).
  final String type;

  /// Titre affiché dans la barre d'application (indépendant du titre de la
  /// page, au cas où celui-ci ne serait pas encore renseigné).
  final String titreEcran;

  const PageContenuScreen({
    super.key,
    required this.type,
    required this.titreEcran,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(pageContenuProvider(type));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titreEcran,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: pageAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (erreur, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: AppColors.error, size: 34),
                  const SizedBox(height: 12),
                  Text(
                    erreur is ApiException
                        ? erreur.message
                        : 'Impossible de charger ce contenu.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(pageContenuProvider(type)),
                    style:
                        ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (page) {
            if (page == null || page.contenu.trim().isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_outlined,
                          color: AppColors.textHint, size: 34),
                      const SizedBox(height: 12),
                      Text(
                        'Ce contenu n\'est pas encore disponible.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (page.publieLe != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Mis à jour le ${Formatters.dateCourte(page.publieLe!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _ContenuHtml(html: page.contenu),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Rendu léger d'un contenu HTML simple (titres, paragraphes, listes) en
/// widgets — l'éditeur riche du panel n'utilise que des balises de base, un
/// moteur HTML complet serait disproportionné pour ce besoin.
class _ContenuHtml extends StatelessWidget {
  final String html;
  const _ContenuHtml({required this.html});

  @override
  Widget build(BuildContext context) {
    final blocs = _parserBlocs(html);
    if (blocs.isEmpty) {
      return Text(
        _texteBrut(html),
        style: const TextStyle(
            fontSize: 14.5, color: AppColors.textPrimary, height: 1.7),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bloc in blocs) ...[
          _rendreBloc(bloc),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _rendreBloc(_Bloc bloc) {
    switch (bloc.type) {
      case _TypeBloc.titre1:
      case _TypeBloc.titre2:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(
            _inlineSpans(bloc.contenu, base: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.4,
            )),
          ),
        );
      case _TypeBloc.titre3:
        return Text.rich(
          _inlineSpans(bloc.contenu, base: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.4,
          )),
        );
      case _TypeBloc.item:
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 8),
                child: Text('•',
                    style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: Text.rich(
                  _inlineSpans(bloc.contenu, base: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  )),
                ),
              ),
            ],
          ),
        );
      case _TypeBloc.paragraphe:
        return Text.rich(
          _inlineSpans(bloc.contenu, base: const TextStyle(
            fontSize: 14.5,
            color: AppColors.textPrimary,
            height: 1.7,
          )),
        );
    }
  }
}

enum _TypeBloc { titre1, titre2, titre3, item, paragraphe }

class _Bloc {
  final _TypeBloc type;
  final String contenu;
  const _Bloc(this.type, this.contenu);
}

final _regexBloc = RegExp(
  r'<(h1|h2|h3|h4|h5|h6|li|p|blockquote)[^>]*>(.*?)</\1>',
  multiLine: true,
  dotAll: true,
  caseSensitive: false,
);

List<_Bloc> _parserBlocs(String html) {
  final sansScripts = html.replaceAll(
    RegExp(r'<(script|style)[^>]*>.*?</\1>',
        multiLine: true, dotAll: true, caseSensitive: false),
    '',
  );

  final blocs = <_Bloc>[];
  for (final match in _regexBloc.allMatches(sansScripts)) {
    final tag = match.group(1)!.toLowerCase();
    final inner = match.group(2)!.trim();
    if (inner.isEmpty) continue;

    final type = switch (tag) {
      'h1' => _TypeBloc.titre1,
      'h2' => _TypeBloc.titre2,
      'h3' || 'h4' || 'h5' || 'h6' => _TypeBloc.titre3,
      'li' => _TypeBloc.item,
      _ => _TypeBloc.paragraphe,
    };
    blocs.add(_Bloc(type, inner));
  }
  return blocs;
}

/// Texte simple (sans balises HTML reconnues) : découpé en paragraphes sur
/// les lignes vides — cas d'un contenu saisi en texte brut.
String _texteBrut(String html) => _decoderEntites(
      html.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
    );

const _entites = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&apos;': "'",
  '&nbsp;': ' ',
};

String _decoderEntites(String texte) {
  var resultat = texte;
  _entites.forEach((entite, valeur) {
    resultat = resultat.replaceAll(entite, valeur);
  });
  return resultat;
}

/// Convertit le HTML interne d'un bloc (gras/italique/sauts de ligne) en
/// spans stylés — les autres balises éventuelles sont simplement retirées.
InlineSpan _inlineSpans(String html, {required TextStyle base}) {
  final normalise = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');

  final spans = <InlineSpan>[];
  final pattern = RegExp(
    r'<(strong|b|em|i)[^>]*>(.*?)</\1>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );

  var position = 0;
  for (final match in pattern.allMatches(normalise)) {
    if (match.start > position) {
      spans.add(TextSpan(
        text: _decoderEntites(
          normalise.substring(position, match.start).replaceAll(RegExp(r'<[^>]*>'), ''),
        ),
      ));
    }
    final tag = match.group(1)!.toLowerCase();
    final texteInterne = _decoderEntites(
      match.group(2)!.replaceAll(RegExp(r'<[^>]*>'), ''),
    );
    final estGras = tag == 'strong' || tag == 'b';
    spans.add(TextSpan(
      text: texteInterne,
      style: TextStyle(
        fontWeight: estGras ? FontWeight.w800 : base.fontWeight,
        fontStyle: estGras ? base.fontStyle : FontStyle.italic,
      ),
    ));
    position = match.end;
  }
  if (position < normalise.length) {
    spans.add(TextSpan(
      text: _decoderEntites(
        normalise.substring(position).replaceAll(RegExp(r'<[^>]*>'), ''),
      ),
    ));
  }

  return TextSpan(style: base, children: spans);
}
