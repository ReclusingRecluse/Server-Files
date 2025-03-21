stock applyDamage(damage, victim, attacker=0)
{ 
  new Handle:dataPack = CreateDataPack();
  WritePackCell(dataPack, damage);  
  WritePackCell(dataPack, victim);
  WritePackCell(dataPack, attacker);

  // Delay damage event by a small amount.
  // Prevents infinite [damage > death > damage > ...] loops.
  CreateTimer(0.10, timer_applyDamage, dataPack);
}