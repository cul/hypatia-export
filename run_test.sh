echo '' > log/test.log
rm -r tmp/47733503f05fb1845bdfd9d85a2d3e36
rm -r tmp/proquest
rm -r tmp/b29a93ef6d902deebdabfb7ccb112577
rm -r tmp/bmc
rm db/test.sqlite3
rake db:migrate RAILS_ENV=test
rake test RAILS_ENV=test # TEST=test/functional/sword_controller_test.rb 
