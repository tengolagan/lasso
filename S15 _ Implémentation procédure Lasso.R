library(glmnet)
library(ISLR)

mydata <- read.csv("C:/Users/nourg/OneDrive/Bureau/MEMOIRE/S15/ONP.csv")
dim(mydata)

noms <-names(mydata) # Nom des variables caract�ristiques 
head(noms)

mydata[,61] <- as.numeric(mydata[,61])
mydata <- mydata[,-1] # Nous supprimons la colonne des liens "URL"
noms <-names(mydata) 

# Histogramme de distributions des variables (pour d�tecter les outliers, les valeurs qui pourraient poser probl�me)
par(mfrow=c(3,4))
for(i in 1:length(mydata))
  {hist(mydata[,i], ylab="Fr�quences", xlab=names(mydata)[i], main="Histogramme de distribution de la variable")}

par(mfrow=c(1,2))
hist(mydata[,2], main="Histogramme de distribution de la variable 'Nb de mots dans le titre'",breaks = 50, col = "skyblue", border = "white")
hist(mydata[,3], main="Histogramme de distribution de la variable 'Nb de mots dans l'article'",breaks = 50, col = "skyblue", border = "white")

# Apr�s avoir parcouru et analys� tous les histogrammes de distributions, nous avons pu identifier diverses probl�mes:

par(mfrow=c(1,2))
hist(mydata[,4], main="Histogramme de distribution de la variable 'Taux de mots uniques'",breaks = 50, col = "skyblue", border = "white") 
# Pr�sence d'outliers ("probl�me d'�chelle"): nous supprimons ces observations

mydata <- mydata[mydata[,4]<1,] #ce sont des taux donc la valeur doit �tre < 1


#Pareil pour les variables 5 et 6 : "n_non_stop_words" et "n_non_stop_unique_tokens" 
mydata <- mydata[mydata[,5]<1,]
mydata <- mydata[mydata[,6]<1,]

noms <-names(mydata) #Mise � jour de la variable Noms 

hist(mydata[,4], main="Histogramme de distribution de la variable 'Taux de mots uniques'",breaks = 50, col = "skyblue", border = "white") 
# L'histogramme est plus coh�rent 


# Les valeurs manquantes correspondent � des 0.
# Il faut donc savoir diff�rencier la valeur manquante de la vraie donn�e.
# A nouveau, en analysant les histogrammes, nous identifions les variables pour lequelles il existe des observations = 0 incoh�rentes 
# (incoh�rence par rapport � la stat concern�e par exemple)


# Par exemple 

par(mfrow=c(1,3))
hist(mydata[,11]) # Longueur moyenne des mots (elle ne peut pas valoir 0)
hist(mydata[,45]) # Perception globale de la polarit� du texte
hist(mydata[,44]) # Subjectivit� globale du texte 
# etc. 

# Nous supprimons ces variables 

for(i in c(11,20,44,45,46,48,49,50,53))
  {mydata <- mydata[mydata[,i]!=0,]} 
noms <-names(mydata)

#_______________________________________________________


# Nous identifions les donn�es asym�triques � droite : 
head(mydata[,3])
head(mydata$shares)
# Nous allons donc les transformer pour r�duire l'asym�trie. 
# Pour les variables dont toutes les valeurs sont sup�rieures � 0, nous prenons le log.
# Pour les autres variables qui peuvent admettre des 0, nous prenons la racine carr�.
# Nous les renommons en ajoutant le pr�fixe log_ pour garder en t�te cette transformation 


for(i in c(3,7,8,9,10,22,26:30,39:43,47, 60)){
  
  if(!sum(mydata[,i]==0)){
    
    mydata[,i] <- log(mydata[,i]); names(mydata)[i] <- paste("log_",names(mydata)[i], sep="")}
  
  else{
    
    mydata[,i] <- sqrt(mydata[,i]); names(mydata)[i] <- paste("sqrt_",names(mydata)[i], sep="")}
}

par(mfrow=c(2,2))
hist(mydata[,19]) 
hist(mydata[,21])
hist(mydata[,23])
hist(mydata[,25])
# Ces variables contiennent des valeurs observ�es n�gatives --> Incoh�rent (erreur de saisie)
# Nous les supprimons. 

mydata <- mydata[, -c(19,21,23,25)]
noms <-names(mydata)

#________________________________ 

# Peut-on omettre les variables relatives au contenu ? 

#  ANALYSE 

ref_lifestyle <- c(which(mydata[,13]==1))
ref_enter <- c(which(mydata[,14]==1))
ref_bus <- c(which(mydata[,15]==1))
ref_socmed <- c(which(mydata[,16]==1))
ref_tech <- c(which(mydata[,17]==1))
ref_world <- c(which(mydata[,18]==1))
ref_autres <- -c(ref_lifestyle,ref_bus,ref_enter,ref_socmed,ref_tech,ref_world)

log_shares <- mydata$log_shares


sub<- list(log_shares[ref_lifestyle],
           log_shares[ref_enter],
           log_shares[ref_bus],
           log_shares[ref_socmed],
           log_shares[ref_tech],
           log_shares[ref_world],
           log_shares[ref_autres])
par(mfrow=c(1,1))
boxplot(sub,xlab="Domaines",main="Nombre de partages de l'article en fonction du contenu",ylab="Log_partages",names=c("Lifestyle",
                                                        "Divertissement",
                                                        "Bus",
                                                        "R�seaux Sociaux",
                                                        "Tech",
                                                        "Monde",
                                                        "Autres"),col=c("cadetblue2"))

# Les niveaux des boxplots diff�rent d'un sujet � l'autre, notamment Lifestyle et R�seaux Sociaux
# Nous les gardons. 


# Peut-on supprimer les variables relatives au jour de publication ? Celles-ci sont du type :
head(mydata$weekday_is_friday)

# ANALYSE : 

mond <- which(mydata$weekday_is_monday==1)
tues <- which(mydata$weekday_is_tuesday==1)
wed <- which(mydata$weekday_is_wednesday==1)
thurs <- which(mydata$weekday_is_thursday==1)
fri <- which(mydata$weekday_is_friday==1)
sat <- which(mydata$weekday_is_saturday==1)
sun <- which(mydata$weekday_is_sunday==1)
we <-  which(mydata$is_weekend==1)

log_shares <- mydata$log_shares


pub_day <- list(log_shares[mond],
           log_shares[tues],
           log_shares[wed],
           log_shares[thurs],
           log_shares[fri],
           log_shares[sat],
           log_shares[sun],
           log_shares[we])

boxplot(pub_day,main="Nombre de partages de l'article en fonction du jour de publication", xlab="Jour de la semaine",ylab="Log_partages",names=c("Lundi",
                                                                       "Mardi",
                                                                       "Mercredi",
                                                                       "Jeudi",
                                                                       "Vendredi",
                                                                       "Samedi",
                                                                       "Dimanche",
                                                                       "Week-end"),col=c("cadetblue2"))

# Pas de diff�rences entre lundi, mardi, mercredi, jeudi vendredi 
# Boxplots �lev�s le week-end 
# Nous gardons seulement l'information semaine VS Week-End

names(mydata)[27:34]
mydata <- mydata[,-c(27:33)]

mydata <- mydata[,-c(28:32)]

dim(mydata)
noms <-names(mydata)

# Nous pr�parons la matrice X des observations :
X <- as.matrix(mydata)
ncol_shares <- ncol(X) # Num de colonne de la variable � expliquer 
X <- X[,-ncol_shares] # On ne garde que les covariables 
dim(X)


# IMPLEMENTATION DE LA PROCEDURE LASSO 

(lasso.mod <- glmnet(X,mydata$log_shares, alpha=1)) #Pour diff�rentes valeurs de Lambda g�n�r�es par d�faut 

# La grille g�n�r�e par d�faut est : 
(lasso.mod$lambda)
beta <- as.matrix(lasso.mod$beta)


# Le nombre de variables s�lectionn�es en fonction de lambda : 
plot(lasso.mod$lambda,lasso.mod$df,type='s',col="red",main="Evolution du nombre de variables s�lectionn�es en fonction de lambda", xlab="Lambda",ylab="Nb de variables s�lectionn�es") #s for step 



# VALIDATION CROISEE 

(lasso.mod.cv <- cv.glmnet(X,mydata$log_shares,alpha=1,nfolds=5))
# Erreur de validation crois�e 
plot(lasso.mod.cv,main="Lasso",ylab="Erreur quadratique moyenne",main=" ")


(lambda.opt.lasso <- lasso.mod.cv$lambda.min)
(coeffs.lasso.cv <- coef(lasso.mod.cv,s="lambda.min"))
