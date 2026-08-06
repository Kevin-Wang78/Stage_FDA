```markdown
# Classification des contours de lésions cutanées par analyse de données fonctionnelles (FDA)

## Description

Ce projet a été réalisé dans le cadre d'un stage de recherche à l'Université de Montréal. Il porte sur la classification de lésions cutanées bénignes et malignes à partir de leurs contours à l'aide de méthodes d'analyse de données fonctionnelles (Functional Data Analysis, FDA).

Les contours sont d'abord lissés et représentés à l'aide d'une base de Fourier. Une étape d'alignement est ensuite réalisée afin de réduire les variations dues à la position et à l'orientation des contours. Une analyse en composantes principales fonctionnelles (FPCA) est ensuite appliquée pour réduire la dimension des données, et les scores obtenus servent d'entrée à différents modèles de classification.

---

## Objectifs

- Représenter les contours des lésions sous forme de fonctions.
- Réaliser le lissage et l'alignement des contours.
- Appliquer une analyse en composantes principales fonctionnelles (FPCA).
- Comparer les performances de plusieurs méthodes de classification.
- Évaluer les modèles à l'aide de différentes mesures de performance.

---

## Structure du projet

```

Projet/
│
├── data/          # Données utilisées
├── scripts/       # Scripts R
├── figures/       # Figures générées
├── results/       # Résultats obtenus
├── rapport/       # Rapport final
└── README.md

````

---

## Prérequis

Le projet a été développé avec **R**.

Packages principaux :

- fda
- caret
- pROC
- ggplot2
- dplyr
- MASS
- pracma

Pour installer les packages :

```r
install.packages(c(
  "fda",
  "caret",
  "pROC",
  "ggplot2",
  "dplyr",
  "MASS",
  "pracma"
))
````

---

## Données

Les données proviennent de la base **HAM10000**.

Les fichiers de données ne sont pas inclus dans ce dépôt en raison de leur taille.

---

## Utilisation

Exécuter les scripts dans l'ordre suivant :

1. Prétraitement des données.
2. Lissage des contours.
3. Alignement des contours.
4. Analyse FPCA.
5. Classification.
6. Évaluation des performances.

---

## Résultats

Les scripts permettent de générer :

* les contours lissés ;
* les contours alignés ;
* les composantes principales fonctionnelles ;
* les scores FPCA ;
* les matrices de confusion ;
* les courbes ROC ;
* les indicateurs de performance (exactitude, sensibilité, spécificité, AUC, etc.).

---

## Auteur

Kevin Wang

Université de Montréal

---

## Références

* Ramsay, J. O., & Silverman, B. W. (2005). *Functional Data Analysis*.
* Ferraty, F., & Vieu, P. (2006). *Nonparametric Functional Data Analysis*.

```
```
