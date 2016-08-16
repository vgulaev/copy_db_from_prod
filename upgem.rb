system("gem build copy_db_from_prod.gemspec")
system("cd ~/workspaces/ekam_dev/ekam && gem install ~/workspaces/copy_db_from_prod/copy_db_from_prod-0.0.2.gem")
# system("cd ~/workspaces/insales_dev/insales && gem install ~/workspaces/copy_db_from_prod/copy_db_from_prod-0.0.2.gem")
