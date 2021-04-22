var MyHash = function(){this.hash_table={};}
MyHash.prototype.set = function(key, value){
   return this.hash_table[key] = value;
}
MyHash.prototype.exists = function(key){
   return key in this.hash_table;
}
MyHash.prototype.get = function(key){
   return this.exists(key)?this.hash_table[key]:null;
}


