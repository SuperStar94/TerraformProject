 <insérer_image>
 
# Terraform-Scaleway 
Terraform est une infrastructure open-source en tant qu'outil de code développé par HashiCorp. Il est utilisé pour définir et provisionner l'infrastructure complète à l'aide d'un langage déclaratif facile à maîtriser.
Il s'agit d'un outil de provisioning d'infrastructure dans lequel nous allons configurer notre infrastructure sous forme de codes.
Dans ce readme j’exposerai l’architecture choisie qui a été déployer chez l’éditeur Scaleway. De plus je décrirai le processus de déploiement, ainsi que des pistes de scaling envisageable pour cette architecture.

### Auteur : 
•	Reechy SAFU (Système et réseau)

## Choix de l’architecture :

### Network
- 1 VPC
- 2 Private Network (app_private_network ; database_private_network)
- 2 Public Gateway (public_gateway_app ; public_gateway_data)

### Load balancer 
Pour le projet, j’ai décidé de mettre en place un load balancer en frontal dont le rôle va être de répartir la charge en direction du serveur actif située en « backend ». En « frontend » et « backend », nous aurons du http et lorsque l’on pointera sur l’adresse IP publique du load balancer : nous atterrirons sur l’interface du serveur qui est en « backend ».
Serveur Web/App
Il s’agit ici d’une instance d’un serveur faisant office de serveur d’application, sur lequel est installé « Ubuntu » avec la solution « Gitlab ».  Un groupe de sécurité est en place, permettant d’autoriser les requêtes sur le port « 80 » pour la communication entre le load balancer et le serveur d’application. Ce groupe de sécurité permet également d’autoriser les requêtes provenant du réseau privé où se situe la base de données.

### Base de données 
La base de données est une instance « RDS » avec le SGBD MySQL 8, qui autorise uniquement la communication avec le réseau privé où est située le serveur d’application : ainsi la base de données sera en mesure de recevoir et de stocker des données provenant du serveur d’application.
Un système de traduction d’adresse de port (PAT), est configuré pour que l’adresse IP et le port de la base données puissent être mapper sur l’adresse IP de la publique gateway.
Architecture système du projet
 
 <insérer_image>
 
Le système est basique pour une première version, mais il est entièrement scalable pour des situations d’évolutions et voici des pistes de scaling : 
•	HA pour le load balancer
•	HA pour le serveur d’application
•	Cluster pour la base de données sur plusieurs nœuds
•	Rajout de load balancer pour la répartition de charge entre les bases de données

## Processus de déploiement
Commencer par générer une clé ssh à l’aide de la commande suivante afin que la clé privé et publique soit trouvé dans /root/.ssh/ (cela servira pour le provisioning) : 
`ssh-keygen -t ed25519`
Installez ensuite le CLI Scaleway pour obtenir les credentials, et pour pouvoir insérer votre clé publique dans votre projet scaleway (mettre « yes » lorsque l’on vous le demande, car elle sera détectée) : 
`scw init`
Créez votre répertoire pour abriter le projet Terraform : 
`mkdir my_terraform_project`
`cd my_terraform_project`
Clonez le répertoire github : 
`git clone https://github.com/SuperStar94/TerraformProject`

À la racine du dossier root du projet terraform, ainsi que dans les dossiers « /modules/web » et « /modules/database » faite la commande : 
`terraform init`

À la racine du dossier root du projet terraform faite (entrez « yes » pour la deuxième commande) : 
`terraform plan`
`terraform apply`

Vous pouvez maintenant pointez sur l’adresse IP publique du load balancer, et profiter de Gitlab ! 😊
