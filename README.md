# Analyse fonctionnelle des données dans les images

## Description

Ce projet a été réalisé dans le cadre d'un stage de recherche à l'Université du Québec à Montréal. Il porte sur la classification de lésions cutanées bénignes et malignes à partir de leurs contours à l'aide de méthodes provenant de l'analyse de données fonctionnelles (ADF).

Les contours sont d'abord lissés et représentés à l'aide d'une base de Fourier. Une étape d'alignement est ensuite réalisée à l'aide de l'Iterative Closest Function (ICF) et d'une rotation des contours. Une analyse en composantes principales fonctionnelles (FPCA) est ensuite appliquée pour réduire la dimension des données, et les scores obtenus servent d'entrée à différents modèles de classification, où chaque modèle a un contour de référence différent.

---

## Publication

L'article associé à ce projet est disponible sur Zenodo notamment :

**Article :** [Analyse fonctionnelle des données dans les images](https://doi.org/10.5281/zenodo.21896795)

**DOI :** [10.5281/zenodo.21896795](https://doi.org/10.5281/zenodo.21896795)

---

## Objectifs

Ce projet vise principalement à montrer que l'utilisation de l'ADF permet de différencier les grains de beauté bénins de ceux de type cancéreux. Autrement dit, il exploite cette branche des mathématiques statistiques à l'aide de notions d'apprentissage automatique, notamment l'analyse en composantes principales, afin de classifier les grains de beauté.

---

## Structure du projet

```text
Projet/
│
├── figures/       # Figures générées
├── code/          # Code avec R
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

Les données originales proviennent de la base de données **HAM10000**. 
Cependant, une partie du prétraitement a été réalisée par Andréa Davila.
Le fichier X_segmented.npy se trouve dans le lien suivant: 
https://drive.google.com/drive/folders/1m8beM0viLixcCELAB5GGaP8yJT8YvV4h?usp=sharing

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

1. les contours lissés ;
2. les contours alignés ;
3. les composantes principales fonctionnelles ;
4. les scores FPCA ;
5. les courbes ROC ;
6. les indicateurs de performance (exactitude, AUC, F1).

---

## Auteurs

**Kevin Wang et Cédric Beaulac**

Université de Montréal
Université du Québec à Montréal

---

## Références principales

* Ramsay, J. O., & Silverman, B. W. (2005). *Functional Data Analysis*.
* Davila, A., Moindjié, I. A., & Beaulac, C. (2026). Comparing shape-based and pixel-based approaches for melanoma detection (Technical report, Université du Québec à Montréal).
* Moindjié, I. A., Beaulac, C., & Descary, M. H. (2025). A Functional Approach to Curve Alignment and Shape Analysis. arXiv preprint arXiv:2503.05632.

