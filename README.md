# Analyse fonctionnelle des données dans les images

## Description

Ce projet a été réalisé dans le cadre d'un stage de recherche à l'Université du Québec à Montréal. Il porte sur la classification de lésions cutanées bénignes et malignes à partir de leurs contours à l'aide de méthodes provenant de l'analyse de données fonctionnelles (ADF).

Les contours sont d'abord lissés et représentés à l'aide d'une base de Fourier. Une étape d'alignement est ensuite réalisée à l'aide de l'Iterative Closest Function (ICF) et d'une rotation des contours. Une analyse en composantes principales fonctionnelles (FPCA) est ensuite appliquée pour réduire la dimension des données, et les scores obtenus servent d'entrée à différents modèles de classification, où chaque modèle a un contour de référence différent.

---

## Objectifs

Ce projet vise principalement à montrer que l'utilisation de l'ADF permet de différencier les grains de beauté bénins de ceux de type cancéreux. Autrement dit, il exploite cette branche des mathématiques statistiques à l'aide de notions d'apprentissage automatique, notamment l'analyse en composantes principales, afin de classifier les grains de beauté.

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

Pour installer les packages :

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

Les données proviennent de la base de données **HAM10000**.

Les fichiers de données ne sont pas inclus dans ce dépôt en raison de leur taille.

---

## Utilisation

Exécuter les scripts dans l'ordre suivant :

1. Prétraitement des données
2. Lissage des contours
3. Alignement des contours
4. FPCA
5. Classification
6. Évaluation des performances (F1, AUC, exactitude)

---

## Résultats

Les scripts permettent de générer :

* les contours lissés ;
* les contours alignés ;
* les composantes principales fonctionnelles ;
* les scores FPCA ;
* les courbes ROC ;
* les indicateurs de performance (exactitude, AUC, F1).

---

## Auteur

**Kevin Wang et Cédric Beaulac**

Université de Montréal
Université du Québec à Montréal

---

## Référence principale

* Ramsay, J. O., & Silverman, B. W. (2005). *Functional Data Analysis*.

