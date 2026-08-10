# Analyse fonctionnelle des données dans les images

## Description

Ce projet a été réalisé dans le cadre d'un stage de recherche à l'Université du Québec à Montréal. Il porte sur la classification de lésions cutanées bénignes et malignes à partir de leurs contours, à l'aide de méthodes provenant de l'analyse de données fonctionnelles (ADF).

Les contours sont d'abord lissés et représentés à l'aide d'une base de Fourier. Une étape d'alignement est ensuite réalisée à l'aide de l'**Iterative Closest Function (ICF)** et d'une étape de rotation des contours. Une **analyse en composantes principales fonctionnelles (FPCA)** est ensuite appliquée afin de réduire la dimension des données. Les scores obtenus servent ensuite d'entrée à différents modèles de classification, chaque modèle utilisant un contour de référence différent.

---

## Objectifs

Ce projet vise principalement à étudier l'utilisation de l'**analyse de données fonctionnelles (ADF)** pour différencier les lésions cutanées bénignes des lésions malignes. L'approche combine des méthodes statistiques fonctionnelles, notamment l'analyse en composantes principales fonctionnelles (FPCA), avec des méthodes d'apprentissage automatique afin de classifier les lésions cutanées.

---

## Structure du projet

```text
Projet/
│
├── data/          # Données utilisées
├── scripts/       # Scripts R
├── figures/       # Figures générées
├── results/       # Résultats obtenus
├── rapport/       # Rapport final
└── README.md
```

---

## Prérequis

Le projet a été développé avec **R**.

### Packages principaux

* `fda`
* `caret`
* `pROC`
* `ggplot2`
* `funData`
* `MFPCA`
* `reticulate`
* `fda.usc`
* `fdasrvf`
* `RcppCNPy`

Pour installer les packages nécessaires :

```r
install.packages(c(
  "fda",
  "caret",
  "pROC",
  "ggplot2",
  "funData",
  "MFPCA",
  "reticulate",
  "fda.usc",
  "fdasrvf",
  "RcppCNPy"
))
```

---

## Données

Les données utilisées proviennent de la base de données **HAM10000**.

Les fichiers de données ne sont pas inclus dans ce dépôt en raison de leur taille.

---

## Méthodologie

La méthodologie générale du projet est composée des étapes suivantes :

1. **Prétraitement des données**
2. **Extraction et représentation des contours**
3. **Lissage des contours à l'aide d'une base de Fourier**
4. **Alignement des contours avec l'ICF et rotation**
5. **Analyse en composantes principales fonctionnelles (FPCA)**
6. **Classification à partir des scores FPCA**
7. **Évaluation des performances**

---

## Utilisation

Les scripts doivent être exécutés dans l'ordre suivant :

1. Prétraitement des données
2. Lissage des contours
3. Alignement des contours
4. FPCA
5. Classification
6. Évaluation des performances

---

## Résultats

Les scripts permettent notamment de générer :

* les contours lissés ;
* les contours alignés ;
* les composantes principales fonctionnelles ;
* les scores FPCA ;
* les courbes ROC ;
* les indicateurs de performance tels que l'exactitude, l'AUC et le score F1.

---

## Auteur

**Kevin Wang et Cédric Beaulac**

Université de Montréal
Université du Québec à Montréal

---

## Référence principale

* Ramsay, J. O., & Silverman, B. W. (2005). *Functional Data Analysis*.

