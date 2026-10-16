# Bendquest verified kernel. Every original gameplay claim is proved below.
# No unsafe definitions, axioms, or unfinished proofs.
import Base

law Bq.Bag:
  Data

def Bq.Bag():
  List<&2, Nat>

law Bq.Maybe:
  (@-A_0: Data -> Data)

def Bq.Maybe(A_0):
  Result<&2, &2, Unit, A_0>

type Bq.Hero is Data:
  Bq.Hero.Hero{inv_0: Bq.Bag, wea_1: Bq.Maybe(Nat), arm_2: Bq.Maybe(Nat), hel_3: Bq.Maybe(Nat), chm_4: Bq.Maybe(Nat), gold_5: Nat, lv_6: Nat, str_7: Nat, agi_8: Nat, vit_9: Nat, pts_10: Nat}

law Bq.hero_gold:
  (@+h_0: Bq.Hero -> Nat)

def Bq.hero_gold(h_0):
  match h_0:
    case Bq.Hero.Hero{field_1, field_2, field_3, field_4, field_5, field_6, field_7, field_8, field_9, field_10, field_11}:
      field_6

law Bq.one:
  (@+k_0: Nat -> Bq.Bag)

def Bq.one(k_0):
  match k_0:
    case Zero{}:
      [1n]
    case Succ{field_12}:
      Con{0n, Bq.one(field_12)}

type Bq.ISlot is Data:
  Bq.ISlot.SlotW{}
  Bq.ISlot.SlotA{}
  Bq.ISlot.SlotH{}
  Bq.ISlot.SlotC{}
  Bq.ISlot.SlotNone{}

type Bq.Info is Data:
  Bq.Info.Info{slot_0: Bq.ISlot, lvreq_1: Nat, streq_2: Nat, agireq_3: Nat, vitreq_4: Nat, atk_5: Nat, df_6: Nat, price_7: Nat}

law Bq.info_potion:
  Bq.Info

def Bq.info_potion():
  Bq.Info.Info{Bq.ISlot.SlotNone{}, 0n, 0n, 0n, 0n, 0n, 0n, 8n}

law Bq.info_weapon:
  (@+k_0: Nat -> Bq.Info)

def Bq.info_weapon(k_0):
  match k_0:
    case Zero{}:
      Bq.Info.Info{Bq.ISlot.SlotW{}, 1n, 0n, 0n, 0n, 3n, 0n, 12n}
    case Succ{field_13}:
      match field_13:
        case Zero{}:
          Bq.Info.Info{Bq.ISlot.SlotW{}, 3n, 4n, 0n, 0n, 6n, 0n, 40n}
        case Succ{field_14}:
          match field_14:
            case Zero{}:
              Bq.Info.Info{Bq.ISlot.SlotW{}, 5n, 5n, 3n, 0n, 10n, 0n, 0n}
            case Succ{field_15}:
              match field_15:
                case Zero{}:
                  Bq.Info.Info{Bq.ISlot.SlotW{}, 7n, 8n, 0n, 0n, 14n, 0n, 90n}
                case Succ{field_16}:
                  match field_16:
                    case Zero{}:
                      Bq.Info.Info{Bq.ISlot.SlotW{}, 10n, 12n, 4n, 0n, 20n, 0n, 0n}
                    case Succ{field_17}:
                      Bq.Info.Info{Bq.ISlot.SlotW{}, 14n, 16n, 8n, 0n, 30n, 0n, 0n}

law Bq.info_armor:
  (@+k_0: Nat -> Bq.Info)

def Bq.info_armor(k_0):
  match k_0:
    case Zero{}:
      Bq.Info.Info{Bq.ISlot.SlotA{}, 1n, 0n, 0n, 0n, 0n, 1n, 10n}
    case Succ{field_18}:
      match field_18:
        case Zero{}:
          Bq.Info.Info{Bq.ISlot.SlotA{}, 3n, 0n, 0n, 3n, 0n, 3n, 35n}
        case Succ{field_19}:
          match field_19:
            case Zero{}:
              Bq.Info.Info{Bq.ISlot.SlotA{}, 7n, 0n, 0n, 6n, 0n, 6n, 80n}
            case Succ{field_20}:
              match field_20:
                case Zero{}:
                  Bq.Info.Info{Bq.ISlot.SlotA{}, 10n, 0n, 3n, 9n, 0n, 9n, 0n}
                case Succ{field_21}:
                  Bq.Info.Info{Bq.ISlot.SlotA{}, 14n, 0n, 6n, 12n, 0n, 13n, 0n}

law Bq.info_helm:
  (@+k_0: Nat -> Bq.Info)

def Bq.info_helm(k_0):
  match k_0:
    case Zero{}:
      Bq.Info.Info{Bq.ISlot.SlotH{}, 2n, 0n, 0n, 0n, 0n, 1n, 15n}
    case Succ{field_22}:
      match field_22:
        case Zero{}:
          Bq.Info.Info{Bq.ISlot.SlotH{}, 6n, 0n, 0n, 5n, 0n, 4n, 0n}
        case Succ{field_23}:
          Bq.Info.Info{Bq.ISlot.SlotH{}, 12n, 0n, 5n, 8n, 0n, 8n, 0n}

law Bq.info_charm:
  (@+k_0: Nat -> Bq.Info)

def Bq.info_charm(k_0):
  match k_0:
    case Zero{}:
      Bq.Info.Info{Bq.ISlot.SlotC{}, 4n, 0n, 3n, 0n, 0n, 0n, 60n}
    case Succ{field_24}:
      match field_24:
        case Zero{}:
          Bq.Info.Info{Bq.ISlot.SlotC{}, 6n, 5n, 0n, 0n, 4n, 0n, 0n}
        case Succ{field_25}:
          Bq.Info.Info{Bq.ISlot.SlotC{}, 9n, 0n, 0n, 5n, 0n, 2n, 0n}

law Bq.Nat.sub:
  (@+a_0: Nat -> (@+b_1: Nat -> Nat))

def Bq.Nat.sub(a_0, b_1):
  match a_0:
    case Zero{}:
      0n
    case Succ{field_26}:
      match b_1:
        case Zero{}:
          Succ{field_26}
        case Succ{field_27}:
          Bq.Nat.sub(field_26, field_27)

law Bq.Nat.le:
  (@+a_0: Nat -> (@+b_1: Nat -> Bool))

def Bq.Nat.le(a_0, b_1):
  match a_0:
    case Zero{}:
      True{}
    case Succ{field_28}:
      match b_1:
        case Zero{}:
          False{}
        case Succ{field_29}:
          Bq.Nat.le(field_28, field_29)

law Bq.item_info:
  (@+k_0: Nat -> Bq.Info)

def Bq.item_info(k_0):
  match k_0:
    case Zero{}:
      Bq.info_potion
    case Succ{field_30}:
      (apply_1 = {(p_0 => \{True: Bq.info_weapon(p_0); \{False: (apply_2 = {(p_0 => \{True: Bq.info_armor(Bq.Nat.sub(p_0, 6n)); \{False: (apply_3 = {(p_0 => \{True: Bq.info_helm(Bq.Nat.sub(p_0, 11n)); \{False: (apply_4 = {(p_0 => \{True: Bq.info_charm(Bq.Nat.sub(p_0, 14n)); \{False: Bq.Info.Info{Bq.ISlot.SlotNone{}, 0n, 0n, 0n, 0n, 0n, 0n, 0n}; \{}}}) : (@+p_0: Nat -> (@+___1: Bool -> Bq.Info))}; apply_4(p_0, Bq.Nat.le(p_0, 16n))); \{}}}) : (@+p_0: Nat -> (@+___1: Bool -> Bq.Info))}; apply_3(p_0, Bq.Nat.le(p_0, 13n))); \{}}}) : (@+p_0: Nat -> (@+___1: Bool -> Bq.Info))}; apply_2(p_0, Bq.Nat.le(p_0, 10n))); \{}}}) : (@+p_0: Nat -> (@+___1: Bool -> Bq.Info))}; apply_1(field_30, Bq.Nat.le(field_30, 5n)))

law Bq.islot:
  (@+k_0: Nat -> Bq.ISlot)

def Bq.islot(k_0):
  (apply_5 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_5(Bq.item_info(k_0)))

law Bq.Bag.sub:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> Bq.Bag))

def Bq.Bag.sub(a_0, b_1):
  match a_0:
    case Con{field_31, field_32}:
      match b_1:
        case Con{field_33, field_34}:
          Con{Bq.Nat.sub(field_31, field_33), Bq.Bag.sub(field_32, field_34)}
        case Nil{}:
          Con{field_31, field_32}
    case Nil{}:
      Nil{}

law Bq.Maybe.some:
  (@-A_0: Data -> (@+value_1: A_0 -> Bq.Maybe(A_0)))

def Bq.Maybe.some(A_0, value_1):
  Done{value_1}

law Bq.do_equip:
  (@+k_0: Nat -> (@+h_1: Bq.Hero -> Bq.Hero))

def Bq.do_equip(k_0, h_1):
  match h_1:
    case Bq.Hero.Hero{field_35, field_36, field_37, field_38, field_39, field_40, field_41, field_42, field_43, field_44, field_45}:
      (apply_6 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_6(field_35, k_0, field_37, field_38, field_39, field_40, field_41, field_42, field_43, field_44, field_45, field_36, Bq.islot(k_0)))

law Bq.mb:
  (@+m_0: Bq.Maybe(Nat) -> Bq.Bag)

def Bq.mb(m_0):
  match m_0:
    case Done{field_46}:
      Bq.one(field_46)
    case Fail{field_47}:
      Nil{}

law Bq.Nat.add:
  (@+a_0: Nat -> (@+b_1: Nat -> Nat))

def Bq.Nat.add(a_0, b_1):
  match a_0:
    case Zero{}:
      b_1
    case Succ{field_48}:
      Succ{Bq.Nat.add(field_48, b_1)}

law Bq.Bag.add:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> Bq.Bag))

def Bq.Bag.add(a_0, b_1):
  match a_0:
    case Con{field_49, field_50}:
      match b_1:
        case Con{field_51, field_52}:
          Con{Bq.Nat.add(field_49, field_51), Bq.Bag.add(field_50, field_52)}
        case Nil{}:
          Con{field_49, field_50}
    case Nil{}:
      b_1

law Bq.Maybe.none:
  (@-A_0: Data -> Bq.Maybe(A_0))

def Bq.Maybe.none(A_0):
  Fail{Unit{}}

law Bq.do_unequip:
  (@+s_0: Bq.ISlot -> (@+h_1: Bq.Hero -> Bq.Hero))

def Bq.do_unequip(s_0, h_1):
  match h_1:
    case Bq.Hero.Hero{field_53, field_54, field_55, field_56, field_57, field_58, field_59, field_60, field_61, field_62, field_63}:
      (apply_7 = {\{Bq.ISlot.SlotW: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.Hero.Hero{Bq.Bag.add(Bq.mb(wea_1), inv_0), Bq.Maybe.none(Nat), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}))))))))))); \{Bq.ISlot.SlotA: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.Hero.Hero{Bq.Bag.add(Bq.mb(arm_2), inv_0), wea_1, Bq.Maybe.none(Nat), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}))))))))))); \{Bq.ISlot.SlotH: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.Hero.Hero{Bq.Bag.add(Bq.mb(hel_3), inv_0), wea_1, arm_2, Bq.Maybe.none(Nat), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}))))))))))); \{Bq.ISlot.SlotC: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.Hero.Hero{Bq.Bag.add(Bq.mb(chm_4), inv_0), wea_1, arm_2, hel_3, Bq.Maybe.none(Nat), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}))))))))))); \{Bq.ISlot.SlotNone: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}))))))))))); \{}}}}}} : (@+___0: Bq.ISlot -> (@+__1: List<&2, Nat> -> (@+__2: Result<&2, &2, Unit, Nat> -> (@+__3: Result<&2, &2, Unit, Nat> -> (@+__4: Result<&2, &2, Unit, Nat> -> (@+__5: Result<&2, &2, Unit, Nat> -> (@+__6: Nat -> (@+__7: Nat -> (@+__8: Nat -> (@+__9: Nat -> (@+__10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))}; apply_7(s_0, field_53, field_54, field_55, field_56, field_57, field_58, field_59, field_60, field_61, field_62, field_63))

law Bq.iprice:
  (@+k_0: Nat -> Nat)

def Bq.iprice(k_0):
  (apply_8 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => price_7)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_8(Bq.item_info(k_0)))

law Bq.do_buy:
  (@+k_0: Nat -> (@+h_1: Bq.Hero -> Bq.Hero))

def Bq.do_buy(k_0, h_1):
  match h_1:
    case Bq.Hero.Hero{field_64, field_65, field_66, field_67, field_68, field_69, field_70, field_71, field_72, field_73, field_74}:
      Bq.Hero.Hero{Bq.Bag.add(Bq.one(k_0), field_64), field_65, field_66, field_67, field_68, Bq.Nat.sub(field_69, Bq.iprice(k_0)), field_70, field_71, field_72, field_73, field_74}

law Bq.POTION:
  Nat

def Bq.POTION():
  0n

law Bq.do_quaff:
  (@+h_0: Bq.Hero -> Bq.Hero)

def Bq.do_quaff(h_0):
  match h_0:
    case Bq.Hero.Hero{field_75, field_76, field_77, field_78, field_79, field_80, field_81, field_82, field_83, field_84, field_85}:
      Bq.Hero.Hero{Bq.Bag.sub(field_75, Bq.one(Bq.POTION)), field_76, field_77, field_78, field_79, field_80, field_81, field_82, field_83, field_84, field_85}

law Bq.do_alloc:
  (@+s_0: Nat -> (@+h_1: Bq.Hero -> Bq.Hero))

def Bq.do_alloc(s_0, h_1):
  match h_1:
    case Bq.Hero.Hero{field_86, field_87, field_88, field_89, field_90, field_91, field_92, field_93, field_94, field_95, field_96}:
      match field_96:
        case Zero{}:
          Bq.Hero.Hero{field_86, field_87, field_88, field_89, field_90, field_91, field_92, field_93, field_94, field_95, 0n}
        case Succ{field_97}:
          (apply_9 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, Succ{str_7}, agi_8, vit_9, p_10}); \{Succ: (p_10 => (apply_10 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, Succ{agi_8}, vit_9, p_10}); \{Succ: (p_10 => (p_11 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, Succ{vit_9}, p_11})); \{}}})))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))}; apply_10(inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, p_10))); \{}}})))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))}; apply_9(field_86, field_87, field_88, field_89, field_90, field_91, field_92, field_93, field_94, field_95, s_0, field_97))

law Bq.do_levelup:
  (@+h_0: Bq.Hero -> Bq.Hero)

def Bq.do_levelup(h_0):
  match h_0:
    case Bq.Hero.Hero{field_98, field_99, field_100, field_101, field_102, field_103, field_104, field_105, field_106, field_107, field_108}:
      Bq.Hero.Hero{field_98, field_99, field_100, field_101, field_102, field_103, Succ{field_104}, field_105, field_106, field_107, Bq.Nat.add(3n, field_108)}

type Bq.HOp is Data:
  Bq.HOp.Equip{k_0: Nat}
  Bq.HOp.Unequip{s_0: Bq.ISlot}
  Bq.HOp.Buy{k_0: Nat}
  Bq.HOp.Quaff{}
  Bq.HOp.Alloc{s_0: Nat}
  Bq.HOp.LevelUp{}

law Bq.hop_do:
  (@+op_0: Bq.HOp -> (@+h_1: Bq.Hero -> Bq.Hero))

def Bq.hop_do(op_0, h_1):
  match op_0:
    case Bq.HOp.Equip{field_109}:
      Bq.do_equip(field_109, h_1)
    case Bq.HOp.Unequip{field_110}:
      Bq.do_unequip(field_110, h_1)
    case Bq.HOp.Buy{field_111}:
      Bq.do_buy(field_111, h_1)
    case Bq.HOp.Quaff{}:
      Bq.do_quaff(h_1)
    case Bq.HOp.Alloc{field_112}:
      Bq.do_alloc(field_112, h_1)
    case Bq.HOp.LevelUp{}:
      Bq.do_levelup(h_1)

law Bq.hero_step_go:
  (@+v_0: Bool -> (@+op_1: Bq.HOp -> (@+h_2: Bq.Hero -> Bq.Hero)))

def Bq.hero_step_go(v_0, op_1, h_2):
  match v_0:
    case True{}:
      Bq.hop_do(op_1, h_2)
    case False{}:
      h_2

law Bq.slot_empty:
  (@+m_0: Bq.Maybe(Nat) -> Bool)

def Bq.slot_empty(m_0):
  match m_0:
    case Done{field_113}:
      False{}
    case Fail{field_114}:
      True{}

law Bq.ilvreq:
  (@+k_0: Nat -> Nat)

def Bq.ilvreq(k_0):
  (apply_11 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_11(Bq.item_info(k_0)))

law Bq.istreq:
  (@+k_0: Nat -> Nat)

def Bq.istreq(k_0):
  (apply_12 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_12(Bq.item_info(k_0)))

law Bq.iagireq:
  (@+k_0: Nat -> Nat)

def Bq.iagireq(k_0):
  (apply_13 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_13(Bq.item_info(k_0)))

law Bq.ivitreq:
  (@+k_0: Nat -> Nat)

def Bq.ivitreq(k_0):
  (apply_14 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_14(Bq.item_info(k_0)))

law Bq.Bool.and:
  (@+a_0: Bool -> (@+b_1: Bool -> Bool))

def Bq.Bool.and(a_0, b_1):
  match a_0:
    case True{}:
      b_1
    case False{}:
      False{}

law Bq.can_wear:
  (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> Bool)))))

def Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4):
  Bq.Bool.and(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))))

law Bq.Bag.le:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> Bool))

def Bq.Bag.le(a_0, b_1):
  match a_0:
    case Con{field_115, field_116}:
      match b_1:
        case Con{field_117, field_118}:
          Bq.Bool.and(Bq.Nat.le(field_115, field_117), Bq.Bag.le(field_116, field_118))
        case Nil{}:
          False{}
    case Nil{}:
      True{}

law Bq.equip_ok:
  (@+k_0: Nat -> (@+h_1: Bq.Hero -> Bool))

def Bq.equip_ok(k_0, h_1):
  (apply_15 = {(k_0 => (h_1 => \{Bq.ISlot.SlotNone: False{}; \{Bq.ISlot.SlotW: (apply_16 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(wea_2), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_16(k_0, h_1)); \{Bq.ISlot.SlotA: (apply_17 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(arm_3), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_17(k_0, h_1)); \{Bq.ISlot.SlotH: (apply_18 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(hel_4), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_18(k_0, h_1)); \{Bq.ISlot.SlotC: (apply_19 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(chm_5), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_19(k_0, h_1)); \{}}}}}})) : (@+k_0: Nat -> (@+h_1: Bq.Hero -> (@+___2: Bq.ISlot -> Bool)))}; apply_15(k_0, h_1, Bq.islot(k_0)))

law Bq.slot_of:
  (@+h_0: Bq.Hero -> (@+s_1: Bq.ISlot -> Bq.Maybe(Nat)))

def Bq.slot_of(h_0, s_1):
  match h_0:
    case Bq.Hero.Hero{field_119, field_120, field_121, field_122, field_123, field_124, field_125, field_126, field_127, field_128, field_129}:
      match s_1:
        case Bq.ISlot.SlotW{}:
          field_120
        case Bq.ISlot.SlotA{}:
          field_121
        case Bq.ISlot.SlotH{}:
          field_122
        case Bq.ISlot.SlotC{}:
          field_123
        case Bq.ISlot.SlotNone{}:
          Bq.Maybe.none(Nat)

law Bq.Bool.not:
  (@+a_0: Bool -> Bool)

def Bq.Bool.not(a_0):
  match a_0:
    case True{}:
      False{}
    case False{}:
      True{}

law Bq.unequip_ok:
  (@+s_0: Bq.ISlot -> (@+h_1: Bq.Hero -> Bool))

def Bq.unequip_ok(s_0, h_1):
  Bq.Bool.not(Bq.slot_empty(Bq.slot_of(h_1, s_0)))

law Bq.Nat.lt:
  (@+a_0: Nat -> (@+b_1: Nat -> Bool))

def Bq.Nat.lt(a_0, b_1):
  Bq.Nat.le(Succ{a_0}, b_1)

law Bq.buy_ok:
  (@+k_0: Nat -> (@+h_1: Bq.Hero -> Bool))

def Bq.buy_ok(k_0, h_1):
  Bq.Bool.and(Bq.Nat.lt(0n, Bq.iprice(k_0)), Bq.Nat.le(Bq.iprice(k_0), Bq.hero_gold(h_1)))

law Bq.quaff_ok:
  (@+h_0: Bq.Hero -> Bool)

def Bq.quaff_ok(h_0):
  match h_0:
    case Bq.Hero.Hero{field_130, field_131, field_132, field_133, field_134, field_135, field_136, field_137, field_138, field_139, field_140}:
      Bq.Bag.le(Bq.one(Bq.POTION), field_130)

law Bq.alloc_ok:
  (@+h_0: Bq.Hero -> Bool)

def Bq.alloc_ok(h_0):
  match h_0:
    case Bq.Hero.Hero{field_141, field_142, field_143, field_144, field_145, field_146, field_147, field_148, field_149, field_150, field_151}:
      Bq.Nat.lt(0n, field_151)

law Bq.hop_ok:
  (@+op_0: Bq.HOp -> (@+h_1: Bq.Hero -> Bool))

def Bq.hop_ok(op_0, h_1):
  match op_0:
    case Bq.HOp.Equip{field_152}:
      Bq.equip_ok(field_152, h_1)
    case Bq.HOp.Unequip{field_153}:
      Bq.unequip_ok(field_153, h_1)
    case Bq.HOp.Buy{field_154}:
      Bq.buy_ok(field_154, h_1)
    case Bq.HOp.Quaff{}:
      Bq.quaff_ok(h_1)
    case Bq.HOp.Alloc{field_155}:
      Bq.alloc_ok(h_1)
    case Bq.HOp.LevelUp{}:
      True{}

law Bq.hero_step:
  (@+op_0: Bq.HOp -> (@+h_1: Bq.Hero -> Bq.Hero))

def Bq.hero_step(op_0, h_1):
  Bq.hero_step_go(Bq.hop_ok(op_0, h_1), op_0, h_1)

law Bq.Nat.mul:
  (@+a_0: Nat -> (@+b_1: Nat -> Nat))

def Bq.Nat.mul(a_0, b_1):
  match a_0:
    case Zero{}:
      0n
    case Succ{field_156}:
      Bq.Nat.add(b_1, Bq.Nat.mul(field_156, b_1))

law Bq.Nat.dbl:
  (@+n_0: Nat -> Nat)

def Bq.Nat.dbl(n_0):
  match n_0:
    case Zero{}:
      0n
    case Succ{field_157}:
      Succ{Succ{Bq.Nat.dbl(field_157)}}

law Bq.Nat.pred:
  (@+n_0: Nat -> Nat)

def Bq.Nat.pred(n_0):
  match n_0:
    case Zero{}:
      0n
    case Succ{field_158}:
      field_158

law Bq.max_hp:
  (@+lv_0: Nat -> (@+vit_1: Nat -> Nat))

def Bq.max_hp(lv_0, vit_1):
  Bq.Nat.add(20n, Bq.Nat.add(Bq.Nat.mul(5n, vit_1), Bq.Nat.dbl(Bq.Nat.pred(lv_0))))

law Bq.crit_dbl:
  (@+crit_0: Bool -> (@+raw_1: Nat -> Nat))

def Bq.crit_dbl(crit_0, raw_1):
  match crit_0:
    case True{}:
      Bq.Nat.dbl(raw_1)
    case False{}:
      raw_1

law Bq.nmin:
  (@+a_0: Nat -> (@+b_1: Nat -> Nat))

def Bq.nmin(a_0, b_1):
  match a_0:
    case Zero{}:
      0n
    case Succ{field_159}:
      match b_1:
        case Zero{}:
          0n
        case Succ{field_160}:
          Succ{Bq.nmin(field_159, field_160)}

law Bq.nmax:
  (@+a_0: Nat -> (@+b_1: Nat -> Nat))

def Bq.nmax(a_0, b_1):
  match a_0:
    case Zero{}:
      b_1
    case Succ{field_161}:
      match b_1:
        case Zero{}:
          Succ{field_161}
        case Succ{field_162}:
          Succ{Bq.nmax(field_161, field_162)}

law Bq.DMG_CAP:
  Nat

def Bq.DMG_CAP():
  999n

law Bq.damage:
  (@+watk_0: Nat -> (@+str_1: Nat -> (@+df_2: Nat -> (@+crit_3: Bool -> Nat))))

def Bq.damage(watk_0, str_1, df_2, crit_3):
  (+raw2_4 = Bq.crit_dbl(crit_3, Bq.Nat.add(watk_0, Bq.Nat.dbl(str_1))); Bq.nmin(Bq.nmax(Bq.Nat.sub(raw2_4, df_2), 1n), Bq.DMG_CAP))

law Bq.iatk:
  (@+k_0: Nat -> Nat)

def Bq.iatk(k_0):
  (apply_20 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => atk_5)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_20(Bq.item_info(k_0)))

law Bq.fresh_hero:
  Bq.Hero

def Bq.fresh_hero():
  Bq.Hero.Hero{Nil{}, Bq.Maybe.none(Nat), Bq.Maybe.none(Nat), Bq.Maybe.none(Nat), Bq.Maybe.none(Nat), 10n, 1n, 3n, 3n, 3n, 0n}

law Bq.idf:
  (@+k_0: Nat -> Nat)

def Bq.idf(k_0):
  (apply_21 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => df_6)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_21(Bq.item_info(k_0)))

law Bq.mob_damage:
  (@+matk_0: Nat -> (@+df_1: Nat -> (@+maxhp_2: Nat -> Nat)))

def Bq.mob_damage(matk_0, df_1, maxhp_2):
  Bq.nmax(Bq.nmin(Bq.nmax(Bq.Nat.sub(matk_0, df_1), 1n), Bq.Nat.pred(maxhp_2)), 1n)

type Bq.Dir is Data:
  Bq.Dir.DU{}
  Bq.Dir.DD{}
  Bq.Dir.DL{}
  Bq.Dir.DR{}

law Bq.walk_x:
  (@+w_0: Nat -> (@+x_1: Nat -> (@+d_2: Bq.Dir -> Nat)))

def Bq.walk_x(w_0, x_1, d_2):
  match d_2:
    case Bq.Dir.DL{}:
      Bq.Nat.pred(x_1)
    case Bq.Dir.DR{}:
      (apply_22 = {(x_0 => \{True: Succ{x_0}; \{False: x_0; \{}}}) : (@+x_0: Nat -> (@+___1: Bool -> Nat))}; apply_22(x_1, Bq.Nat.lt(Succ{x_1}, w_0)))
    case Bq.Dir.DU{}:
      x_1
    case Bq.Dir.DD{}:
      x_1

law Bq.walk_y:
  (@+h_0: Nat -> (@+y_1: Nat -> (@+d_2: Bq.Dir -> Nat)))

def Bq.walk_y(h_0, y_1, d_2):
  match d_2:
    case Bq.Dir.DU{}:
      Bq.Nat.pred(y_1)
    case Bq.Dir.DD{}:
      (apply_23 = {(y_0 => \{True: Succ{y_0}; \{False: y_0; \{}}}) : (@+y_0: Nat -> (@+___1: Bool -> Nat))}; apply_23(y_1, Bq.Nat.lt(Succ{y_1}, h_0)))
    case Bq.Dir.DL{}:
      y_1
    case Bq.Dir.DR{}:
      y_1

law Bq.Pair.Pair:
  (@-A_0: Data -> (@-B_1: (@-__1: A_0 -> Data) -> Data))

def Bq.Pair.Pair(A_0, B_1):
  Sigma<&2, &2, A_0, B_1>

law Bq.walk:
  (@+w_0: Nat -> (@+h_1: Nat -> (@+x_2: Nat -> (@+y_3: Nat -> (@+d_4: Bq.Dir -> Bq.Pair.Pair(Nat, (__5 => Nat)))))))

def Bq.walk(w_0, h_1, x_2, y_3, d_4):
  Tuple{Bq.walk_x(w_0, x_2, d_4), Bq.walk_y(h_1, y_3, d_4)}

law Bq.rejected_op_is_noop:
  (@+op_0: Bq.HOp -> (@+h_1: Bq.Hero -> (@+__2: {Bq.hop_ok(op_0, h_1) == False{} : Bool} -> {Bq.hero_step(op_0, h_1) == h_1 : Bq.Hero})))

def Bq.rejected_op_is_noop(op_0, h_1, __2):
  (%Equal.sym(Bool, Bq.hop_ok(op_0, h_1), False{}, __2) : {Bq.hero_step_go(_, op_0, h_1) == h_1 : Bq.Hero}; {==})

law Bq.gear_bag:
  (@+wea_0: Bq.Maybe(Nat) -> (@+arm_1: Bq.Maybe(Nat) -> (@+hel_2: Bq.Maybe(Nat) -> (@+chm_3: Bq.Maybe(Nat) -> Bq.Bag))))

def Bq.gear_bag(wea_0, arm_1, hel_2, chm_3):
  Bq.Bag.add(Bq.mb(wea_0), Bq.Bag.add(Bq.mb(arm_1), Bq.Bag.add(Bq.mb(hel_2), Bq.mb(chm_3))))

law Bq.census:
  (@+h_0: Bq.Hero -> Bq.Bag)

def Bq.census(h_0):
  match h_0:
    case Bq.Hero.Hero{field_163, field_164, field_165, field_166, field_167, field_168, field_169, field_170, field_171, field_172, field_173}:
      Bq.Bag.add(field_163, Bq.gear_bag(field_164, field_165, field_166, field_167))

law Bq.Nat.add_zero:
  (@+a_0: Nat -> {Bq.Nat.add(a_0, 0n) == a_0 : Nat})

def Bq.Nat.add_zero(a_0):
  match a_0:
    case Zero{}:
      {==}
    case Succ{field_174}:
      (%Equal.sym(Nat, Bq.Nat.add(field_174, 0n), field_174, Bq.Nat.add_zero(field_174)) : {Succ{_} == Succ{field_174} : Nat}; {==})

law Bq.Nat.add_succ:
  (@+a_0: Nat -> (@+b_1: Nat -> {Bq.Nat.add(a_0, Succ{b_1}) == Succ{Bq.Nat.add(a_0, b_1)} : Nat}))

def Bq.Nat.add_succ(a_0, b_1):
  match a_0:
    case Zero{}:
      {==}
    case Succ{field_175}:
      (%Equal.sym(Nat, Bq.Nat.add(field_175, Succ{b_1}), Succ{Bq.Nat.add(field_175, b_1)}, Bq.Nat.add_succ(field_175, b_1)) : {Succ{_} == Succ{Succ{Bq.Nat.add(field_175, b_1)}} : Nat}; {==})

law Bq.Nat.add_comm:
  (@+a_0: Nat -> (@+b_1: Nat -> {Bq.Nat.add(a_0, b_1) == Bq.Nat.add(b_1, a_0) : Nat}))

def Bq.Nat.add_comm(a_0, b_1):
  match a_0:
    case Zero{}:
      (%Equal.sym(Nat, Bq.Nat.add(b_1, 0n), b_1, Bq.Nat.add_zero(b_1)) : {b_1 == _ : Nat}; {==})
    case Succ{field_176}:
      (%Equal.sym(Nat, Bq.Nat.add(b_1, Succ{field_176}), Succ{Bq.Nat.add(b_1, field_176)}, Bq.Nat.add_succ(b_1, field_176)) : {Succ{Bq.Nat.add(field_176, b_1)} == _ : Nat}; (%Equal.sym(Nat, Bq.Nat.add(field_176, b_1), Bq.Nat.add(b_1, field_176), Bq.Nat.add_comm(field_176, b_1)) : {Succ{_} == Succ{Bq.Nat.add(b_1, field_176)} : Nat}; {==}))

law Bq.Bag.add_nil:
  (@+a_0: Bq.Bag -> {Bq.Bag.add(a_0, Nil{}) == a_0 : Bq.Bag})

def Bq.Bag.add_nil(a_0):
  match a_0:
    case Con{field_177, field_178}:
      {==}
    case Nil{}:
      {==}

law Bq.Bag.add_comm:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> {Bq.Bag.add(a_0, b_1) == Bq.Bag.add(b_1, a_0) : Bq.Bag}))

def Bq.Bag.add_comm(a_0, b_1):
  match a_0:
    case Con{field_179, field_180}:
      match b_1:
        case Con{field_181, field_182}:
          (%Equal.sym(Nat, Bq.Nat.add(field_179, field_181), Bq.Nat.add(field_181, field_179), Bq.Nat.add_comm(field_179, field_181)) : {Con{_, Bq.Bag.add(field_180, field_182)} == Con{Bq.Nat.add(field_181, field_179), Bq.Bag.add(field_182, field_180)} : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(field_180, field_182), Bq.Bag.add(field_182, field_180), Bq.Bag.add_comm(field_180, field_182)) : {Con{Bq.Nat.add(field_181, field_179), _} == Con{Bq.Nat.add(field_181, field_179), Bq.Bag.add(field_182, field_180)} : List<&2, Nat>}; {==}))
        case Nil{}:
          {==}
    case Nil{}:
      (%Equal.sym(Bq.Bag, Bq.Bag.add(b_1, Nil{}), b_1, Bq.Bag.add_nil(b_1)) : {b_1 == _ : List<&2, Nat>}; {==})

law Bq.Nat.add_assoc:
  (@+a_0: Nat -> (@+b_1: Nat -> (@+c_2: Nat -> {Bq.Nat.add(Bq.Nat.add(a_0, b_1), c_2) == Bq.Nat.add(a_0, Bq.Nat.add(b_1, c_2)) : Nat})))

def Bq.Nat.add_assoc(a_0, b_1, c_2):
  match a_0:
    case Zero{}:
      {==}
    case Succ{field_183}:
      (%Equal.sym(Nat, Bq.Nat.add(Bq.Nat.add(field_183, b_1), c_2), Bq.Nat.add(field_183, Bq.Nat.add(b_1, c_2)), Bq.Nat.add_assoc(field_183, b_1, c_2)) : {Succ{_} == Succ{Bq.Nat.add(field_183, Bq.Nat.add(b_1, c_2))} : Nat}; {==})

law Bq.Bag.add_assoc:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> (@+c_2: Bq.Bag -> {Bq.Bag.add(Bq.Bag.add(a_0, b_1), c_2) == Bq.Bag.add(a_0, Bq.Bag.add(b_1, c_2)) : Bq.Bag})))

def Bq.Bag.add_assoc(a_0, b_1, c_2):
  match a_0:
    case Con{field_184, field_185}:
      match b_1:
        case Con{field_186, field_187}:
          match c_2:
            case Con{field_188, field_189}:
              (%Equal.sym(Nat, Bq.Nat.add(Bq.Nat.add(field_184, field_186), field_188), Bq.Nat.add(field_184, Bq.Nat.add(field_186, field_188)), Bq.Nat.add_assoc(field_184, field_186, field_188)) : {Con{_, Bq.Bag.add(Bq.Bag.add(field_185, field_187), field_189)} == Con{Bq.Nat.add(field_184, Bq.Nat.add(field_186, field_188)), Bq.Bag.add(field_185, Bq.Bag.add(field_187, field_189))} : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.Bag.add(field_185, field_187), field_189), Bq.Bag.add(field_185, Bq.Bag.add(field_187, field_189)), Bq.Bag.add_assoc(field_185, field_187, field_189)) : {Con{Bq.Nat.add(field_184, Bq.Nat.add(field_186, field_188)), _} == Con{Bq.Nat.add(field_184, Bq.Nat.add(field_186, field_188)), Bq.Bag.add(field_185, Bq.Bag.add(field_187, field_189))} : List<&2, Nat>}; {==}))
            case Nil{}:
              {==}
        case Nil{}:
          {==}
    case Nil{}:
      {==}

law Bq.bag_swap:
  (@+x_0: Bq.Bag -> (@+y_1: Bq.Bag -> (@+z_2: Bq.Bag -> {Bq.Bag.add(x_0, Bq.Bag.add(y_1, z_2)) == Bq.Bag.add(y_1, Bq.Bag.add(x_0, z_2)) : Bq.Bag})))

def Bq.bag_swap(x_0, y_1, z_2):
  (%Equal.sym(Bq.Bag, Bq.Bag.add(x_0, Bq.Bag.add(y_1, z_2)), Bq.Bag.add(Bq.Bag.add(y_1, z_2), x_0), Bq.Bag.add_comm(x_0, Bq.Bag.add(y_1, z_2))) : {_ == Bq.Bag.add(y_1, Bq.Bag.add(x_0, z_2)) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.Bag.add(y_1, z_2), x_0), Bq.Bag.add(y_1, Bq.Bag.add(z_2, x_0)), Bq.Bag.add_assoc(y_1, z_2, x_0)) : {_ == Bq.Bag.add(y_1, Bq.Bag.add(x_0, z_2)) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(z_2, x_0), Bq.Bag.add(x_0, z_2), Bq.Bag.add_comm(z_2, x_0)) : {Bq.Bag.add(y_1, _) == Bq.Bag.add(y_1, Bq.Bag.add(x_0, z_2)) : List<&2, Nat>}; {==})))

law Bq.Bool.BoolD:
  (@+x_0: Bool -> (@tc_1: Data -> (@fc_2: Data -> Data)))

def Bq.Bool.BoolD(x_0, tc_1, fc_2):
  match x_0:
    case True{}:
      tc_1
    case False{}:
      fc_2

law Bq.Bool.false_ne_true:
  (@+e_0: {False{} == True{} : Bool} -> Empty)

def Bq.Bool.false_ne_true(e_0):
  (%Equal.sym(Bool, False{}, True{}, e_0) : Bq.Bool.BoolD(_, Unit, Empty); Unit{})

law Bq.Nat.add_sub_cancel:
  (@+x_0: Nat -> (@+y_1: Nat -> (@+__2: {Bq.Nat.le(x_0, y_1) == True{} : Bool} -> {Bq.Nat.add(x_0, Bq.Nat.sub(y_1, x_0)) == y_1 : Nat})))

def Bq.Nat.add_sub_cancel(x_0, y_1, __2):
  match x_0:
    case Zero{}:
      match y_1:
        case Zero{}:
          {==}
        case Succ{field_190}:
          {==}
    case Succ{field_191}:
      match y_1:
        case Zero{}:
          (apply_24 = {(xp_0 => \{}) : (@-xp_0: Nat -> (@+___1: Empty -> {Succ{Bq.Nat.add(xp_0, 0n)} == 0n : Nat}))}; apply_24(field_191, Bq.Bool.false_ne_true(__2)))
        case Succ{field_192}:
          (%Equal.sym(Nat, Bq.Nat.add(field_191, Bq.Nat.sub(field_192, field_191)), field_192, Bq.Nat.add_sub_cancel(field_191, field_192, __2)) : {Succ{_} == Succ{field_192} : Nat}; {==})

law Bq.Bool.and_l:
  (@+x_0: Bool -> (@+y_1: Bool -> (@+e_2: {Bq.Bool.and(x_0, y_1) == True{} : Bool} -> {x_0 == True{} : Bool})))

def Bq.Bool.and_l(x_0, y_1, e_2):
  match x_0:
    case True{}:
      {==}
    case False{}:
      e_2

law Bq.Bool.and_r:
  (@+x_0: Bool -> (@+y_1: Bool -> (@+e_2: {Bq.Bool.and(x_0, y_1) == True{} : Bool} -> {y_1 == True{} : Bool})))

def Bq.Bool.and_r(x_0, y_1, e_2):
  match x_0:
    case True{}:
      e_2
    case False{}:
      match y_1:
        case True{}:
          {==}
        case False{}:
          e_2

law Bq.Bag.add_sub_cancel:
  (@+a_0: Bq.Bag -> (@+b_1: Bq.Bag -> (@+__2: {Bq.Bag.le(a_0, b_1) == True{} : Bool} -> {Bq.Bag.add(a_0, Bq.Bag.sub(b_1, a_0)) == b_1 : Bq.Bag})))

def Bq.Bag.add_sub_cancel(a_0, b_1, __2):
  match a_0:
    case Con{field_193, field_194}:
      match b_1:
        case Con{field_195, field_196}:
          (%Equal.sym(Nat, Bq.Nat.add(field_193, Bq.Nat.sub(field_195, field_193)), field_195, Bq.Nat.add_sub_cancel(field_193, field_195, Bq.Bool.and_l(Bq.Nat.le(field_193, field_195), Bq.Bag.le(field_194, field_196), __2))) : {Con{_, Bq.Bag.add(field_194, Bq.Bag.sub(field_196, field_194))} == Con{field_195, field_196} : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(field_194, Bq.Bag.sub(field_196, field_194)), field_196, Bq.Bag.add_sub_cancel(field_194, field_196, Bq.Bool.and_r(Bq.Nat.le(field_193, field_195), Bq.Bag.le(field_194, field_196), __2))) : {Con{field_195, _} == Con{field_195, field_196} : List<&2, Nat>}; {==}))
        case Nil{}:
          (apply_25 = {(x_0 => (xs_1 => \{})) : (@-x_0: Nat -> (@-xs_1: List<&2, Nat> -> (@+___2: Empty -> {Con{x_0, xs_1} == Nil{} : List<&2, Nat>})))}; apply_25(field_193, field_194, Bq.Bool.false_ne_true(__2)))
    case Nil{}:
      match b_1:
        case Con{field_197, field_198}:
          {==}
        case Nil{}:
          {==}

law Bq.equip_shuffle:
  (@+i_0: Bq.Bag -> (@+k1_1: Bq.Bag -> (@+r_2: Bq.Bag -> (@+has_3: {Bq.Bag.le(k1_1, i_0) == True{} : Bool} -> {Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), Bq.Bag.add(k1_1, r_2)) == Bq.Bag.add(i_0, r_2) : Bq.Bag}))))

def Bq.equip_shuffle(i_0, k1_1, r_2, has_3):
  (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), Bq.Bag.add(k1_1, r_2)), Bq.Bag.add(k1_1, Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), r_2)), Bq.bag_swap(Bq.Bag.sub(i_0, k1_1), k1_1, r_2)) : {_ == Bq.Bag.add(i_0, r_2) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(k1_1, Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), r_2)), Bq.Bag.add(Bq.Bag.add(k1_1, Bq.Bag.sub(i_0, k1_1)), r_2), Equal.sym(Bq.Bag, Bq.Bag.add(Bq.Bag.add(k1_1, Bq.Bag.sub(i_0, k1_1)), r_2), Bq.Bag.add(k1_1, Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), r_2)), Bq.Bag.add_assoc(k1_1, Bq.Bag.sub(i_0, k1_1), r_2))) : {_ == Bq.Bag.add(i_0, r_2) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(k1_1, Bq.Bag.sub(i_0, k1_1)), i_0, Bq.Bag.add_sub_cancel(k1_1, i_0, has_3)) : {Bq.Bag.add(_, r_2) == Bq.Bag.add(i_0, r_2) : List<&2, Nat>}; {==})))

law Bq.equip_shuffle_chm:
  (@+i_0: Bq.Bag -> (@+k1_1: Bq.Bag -> (@+w_2: Bq.Bag -> (@+a_3: Bq.Bag -> (@+hb_4: Bq.Bag -> (@+has_5: {Bq.Bag.le(k1_1, i_0) == True{} : Bool} -> {Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), Bq.Bag.add(w_2, Bq.Bag.add(a_3, Bq.Bag.add(hb_4, k1_1)))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, Bq.Bag.add(hb_4, Nil{})))) : Bq.Bag}))))))

def Bq.equip_shuffle_chm(i_0, k1_1, w_2, a_3, hb_4, has_5):
  (%Equal.sym(Bq.Bag, Bq.Bag.add(hb_4, Nil{}), hb_4, Bq.Bag.add_nil(hb_4)) : {Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), Bq.Bag.add(w_2, Bq.Bag.add(a_3, Bq.Bag.add(hb_4, k1_1)))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, _))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(hb_4, k1_1), Bq.Bag.add(k1_1, hb_4), Bq.Bag.add_comm(hb_4, k1_1)) : {Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), Bq.Bag.add(w_2, Bq.Bag.add(a_3, _))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(a_3, Bq.Bag.add(k1_1, hb_4)), Bq.Bag.add(k1_1, Bq.Bag.add(a_3, hb_4)), Bq.bag_swap(a_3, k1_1, hb_4)) : {Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), Bq.Bag.add(w_2, _)) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(w_2, Bq.Bag.add(k1_1, Bq.Bag.add(a_3, hb_4))), Bq.Bag.add(k1_1, Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4))), Bq.bag_swap(w_2, k1_1, Bq.Bag.add(a_3, hb_4))) : {Bq.Bag.add(Bq.Bag.sub(i_0, k1_1), _) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4))) : List<&2, Nat>}; Bq.equip_shuffle(i_0, k1_1, Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4)), has_5)))))

law Bq.equip_preserves_census:
  (@+k_0: Nat -> (@+h_1: Bq.Hero -> {Bq.census(Bq.hero_step(Bq.HOp.Equip{k_0}, h_1)) == Bq.census(h_1) : Bq.Bag}))

def Bq.equip_preserves_census(k_0, h_1):
  match h_1:
    case Bq.Hero.Hero{field_199, field_200, field_201, field_202, field_203, field_204, field_205, field_206, field_207, field_208, field_209}:
      (apply_26 = {(k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => \{Bq.ISlot.SlotNone: (ei_12 => {==}); \{Bq.ISlot.SlotW: (ei_12 => (apply_27 = {(k_0 => (inv_1 => (wea_2 => (lv_3 => (str_4 => (agi_5 => (vit_6 => (arm_7 => (hel_8 => (chm_9 => (gold_10 => (pts_11 => (ei_12 => \{False: (has_13 => {==}); \{True: (apply_28 = {(k_0 => (inv_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (arm_6 => (hel_7 => (chm_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => (has_13 => {==})); \{Fail: (error_12 => (has_13 => (apply_29 = {(k_0 => (inv_1 => (error_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (ei_12 => (has_13 => \{False: {==}; \{True: (%Equal.sym(Bq.ISlot, (apply_30 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_30(Bq.item_info(k_0))), Bq.ISlot.SlotW{}, ei_12) : {Bq.census((apply_31 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_31(inv_1, k_0, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, Fail{error_2}, _))) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(arm_3), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5)))) : List<&2, Nat>}; Bq.equip_shuffle(inv_1, Bq.one(k_0), Bq.Bag.add(Bq.mb(arm_3), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5))), has_13)); \{}}})))))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@-error_2: Unit -> (@+arm_3: Bq.Maybe(Nat) -> (@+hel_4: Bq.Maybe(Nat) -> (@+chm_5: Bq.Maybe(Nat) -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_32 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_32(Bq.item_info(k_0))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+has_13: {Bq.Bag.le(Bq.one(k_0), inv_1) == True{} : Bool} -> (@+___14: Bool -> {Bq.census(Bq.hero_step_go(___14, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, Fail{error_2}, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(arm_3), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5)))) : List<&2, Nat>})))))))))))))))}; apply_29(k_0, inv_1, error_12, arm_6, hel_7, chm_8, gold_9, lv_2, str_3, agi_4, vit_5, pts_10, ei_11, has_13, Bq.can_wear(k_0, lv_2, str_3, agi_4, vit_5))))); \{}}})))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@+arm_6: Bq.Maybe(Nat) -> (@+hel_7: Bq.Maybe(Nat) -> (@+chm_8: Bq.Maybe(Nat) -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_33 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_33(Bq.item_info(k_0))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> (@+__13: {Bq.Bag.le(Bq.one(k_0), inv_1) == True{} : Bool} -> {Bq.census(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le((apply_34 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_34(Bq.item_info(k_0))), lv_2), Bq.Bool.and(Bq.Nat.le((apply_35 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_35(Bq.item_info(k_0))), str_3), Bq.Bool.and(Bq.Nat.le((apply_36 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_36(Bq.item_info(k_0))), agi_4), Bq.Nat.le((apply_37 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_37(Bq.item_info(k_0))), vit_5))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, ___12, arm_6, hel_7, chm_8, gold_9, lv_2, str_3, agi_4, vit_5, pts_10})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(___12), Bq.Bag.add(Bq.mb(arm_6), Bq.Bag.add(Bq.mb(hel_7), Bq.mb(chm_8))))) : List<&2, Nat>}))))))))))))))}; apply_28(k_0, inv_1, lv_3, str_4, agi_5, vit_6, arm_7, hel_8, chm_9, gold_10, pts_11, ei_12, wea_2)); \{}}}))))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+wea_2: Bq.Maybe(Nat) -> (@+lv_3: Nat -> (@+str_4: Nat -> (@+agi_5: Nat -> (@+vit_6: Nat -> (@+arm_7: Bq.Maybe(Nat) -> (@+hel_8: Bq.Maybe(Nat) -> (@+chm_9: Bq.Maybe(Nat) -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_38 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_38(Bq.item_info(k_0))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+___13: Bool -> (@+_e_14: {Bq.Bag.le(Bq.one(k_0), inv_1) == ___13 : Bool} -> {Bq.census(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(wea_2), Bq.Bool.and(Bq.Nat.le((apply_39 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_39(Bq.item_info(k_0))), lv_3), Bq.Bool.and(Bq.Nat.le((apply_40 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_40(Bq.item_info(k_0))), str_4), Bq.Bool.and(Bq.Nat.le((apply_41 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_41(Bq.item_info(k_0))), agi_5), Bq.Nat.le((apply_42 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_42(Bq.item_info(k_0))), vit_6)))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, arm_7, hel_8, chm_9, gold_10, lv_3, str_4, agi_5, vit_6, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_7), Bq.Bag.add(Bq.mb(hel_8), Bq.mb(chm_9))))) : List<&2, Nat>})))))))))))))))}; apply_27(k_0, inv_1, wea_2, lv_7, str_8, agi_9, vit_10, arm_3, hel_4, chm_5, gold_6, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_1), {==}))); \{Bq.ISlot.SlotA: (ei_12 => (apply_43 = {(k_0 => (inv_1 => (arm_2 => (lv_3 => (str_4 => (agi_5 => (vit_6 => (wea_7 => (hel_8 => (chm_9 => (gold_10 => (pts_11 => (ei_12 => \{False: (has_13 => {==}); \{True: (apply_44 = {(k_0 => (inv_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (wea_6 => (hel_7 => (chm_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => (has_13 => {==})); \{Fail: (error_12 => (has_13 => (apply_45 = {(k_0 => (inv_1 => (wea_2 => (error_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (ei_12 => (has_13 => \{False: {==}; \{True: (%Equal.sym(Bq.ISlot, (apply_46 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_46(Bq.item_info(k_0))), Bq.ISlot.SlotA{}, ei_12) : {Bq.census((apply_47 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_47(inv_1, k_0, Fail{error_3}, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, wea_2, _))) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5)))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.one(k_0), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5)))), Bq.Bag.add(Bq.one(k_0), Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5)))), Bq.bag_swap(Bq.mb(wea_2), Bq.one(k_0), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5)))) : {Bq.Bag.add(Bq.Bag.sub(inv_1, Bq.one(k_0)), _) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5)))) : List<&2, Nat>}; Bq.equip_shuffle(inv_1, Bq.one(k_0), Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5))), has_13))); \{}}})))))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+wea_2: Bq.Maybe(Nat) -> (@-error_3: Unit -> (@+hel_4: Bq.Maybe(Nat) -> (@+chm_5: Bq.Maybe(Nat) -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_48 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_48(Bq.item_info(k_0))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+has_13: {Bq.Bag.le(Bq.one(k_0), inv_1) == True{} : Bool} -> (@+___14: Bool -> {Bq.census(Bq.hero_step_go(___14, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, Fail{error_3}, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5)))) : List<&2, Nat>})))))))))))))))}; apply_45(k_0, inv_1, wea_6, error_12, hel_7, chm_8, gold_9, lv_2, str_3, agi_4, vit_5, pts_10, ei_11, has_13, Bq.can_wear(k_0, lv_2, str_3, agi_4, vit_5))))); \{}}})))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@+wea_6: Bq.Maybe(Nat) -> (@+hel_7: Bq.Maybe(Nat) -> (@+chm_8: Bq.Maybe(Nat) -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_49 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_49(Bq.item_info(k_0))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> (@+__13: {Bq.Bag.le(Bq.one(k_0), inv_1) == True{} : Bool} -> {Bq.census(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le((apply_50 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_50(Bq.item_info(k_0))), lv_2), Bq.Bool.and(Bq.Nat.le((apply_51 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_51(Bq.item_info(k_0))), str_3), Bq.Bool.and(Bq.Nat.le((apply_52 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_52(Bq.item_info(k_0))), agi_4), Bq.Nat.le((apply_53 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_53(Bq.item_info(k_0))), vit_5))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_6, ___12, hel_7, chm_8, gold_9, lv_2, str_3, agi_4, vit_5, pts_10})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_6), Bq.Bag.add(Bq.mb(___12), Bq.Bag.add(Bq.mb(hel_7), Bq.mb(chm_8))))) : List<&2, Nat>}))))))))))))))}; apply_44(k_0, inv_1, lv_3, str_4, agi_5, vit_6, wea_7, hel_8, chm_9, gold_10, pts_11, ei_12, arm_2)); \{}}}))))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+arm_2: Bq.Maybe(Nat) -> (@+lv_3: Nat -> (@+str_4: Nat -> (@+agi_5: Nat -> (@+vit_6: Nat -> (@+wea_7: Bq.Maybe(Nat) -> (@+hel_8: Bq.Maybe(Nat) -> (@+chm_9: Bq.Maybe(Nat) -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_54 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_54(Bq.item_info(k_0))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+___13: Bool -> (@+_e_14: {Bq.Bag.le(Bq.one(k_0), inv_1) == ___13 : Bool} -> {Bq.census(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(arm_2), Bq.Bool.and(Bq.Nat.le((apply_55 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_55(Bq.item_info(k_0))), lv_3), Bq.Bool.and(Bq.Nat.le((apply_56 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_56(Bq.item_info(k_0))), str_4), Bq.Bool.and(Bq.Nat.le((apply_57 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_57(Bq.item_info(k_0))), agi_5), Bq.Nat.le((apply_58 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_58(Bq.item_info(k_0))), vit_6)))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_7, arm_2, hel_8, chm_9, gold_10, lv_3, str_4, agi_5, vit_6, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_7), Bq.Bag.add(Bq.mb(arm_2), Bq.Bag.add(Bq.mb(hel_8), Bq.mb(chm_9))))) : List<&2, Nat>})))))))))))))))}; apply_43(k_0, inv_1, arm_3, lv_7, str_8, agi_9, vit_10, wea_2, hel_4, chm_5, gold_6, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_1), {==}))); \{Bq.ISlot.SlotH: (ei_12 => (apply_59 = {(k_0 => (inv_1 => (hel_2 => (lv_3 => (str_4 => (agi_5 => (vit_6 => (wea_7 => (arm_8 => (chm_9 => (gold_10 => (pts_11 => (ei_12 => \{False: (has_13 => {==}); \{True: (apply_60 = {(k_0 => (inv_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (wea_6 => (arm_7 => (chm_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => (has_13 => {==})); \{Fail: (error_12 => (has_13 => (apply_61 = {(k_0 => (inv_1 => (wea_2 => (arm_3 => (error_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (ei_12 => (has_13 => \{False: {==}; \{True: (%Equal.sym(Bq.ISlot, (apply_62 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_62(Bq.item_info(k_0))), Bq.ISlot.SlotH{}, ei_12) : {Bq.census((apply_63 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_63(inv_1, k_0, arm_3, Fail{error_4}, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, wea_2, _))) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5)))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.mb(arm_3), Bq.Bag.add(Bq.one(k_0), Bq.mb(chm_5))), Bq.Bag.add(Bq.one(k_0), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5))), Bq.bag_swap(Bq.mb(arm_3), Bq.one(k_0), Bq.mb(chm_5))) : {Bq.Bag.add(Bq.Bag.sub(inv_1, Bq.one(k_0)), Bq.Bag.add(Bq.mb(wea_2), _)) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5)))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.one(k_0), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5)))), Bq.Bag.add(Bq.one(k_0), Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5)))), Bq.bag_swap(Bq.mb(wea_2), Bq.one(k_0), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5)))) : {Bq.Bag.add(Bq.Bag.sub(inv_1, Bq.one(k_0)), _) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5)))) : List<&2, Nat>}; Bq.equip_shuffle(inv_1, Bq.one(k_0), Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5))), has_13)))); \{}}})))))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+wea_2: Bq.Maybe(Nat) -> (@+arm_3: Bq.Maybe(Nat) -> (@-error_4: Unit -> (@+chm_5: Bq.Maybe(Nat) -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_64 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_64(Bq.item_info(k_0))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+has_13: {Bq.Bag.le(Bq.one(k_0), inv_1) == True{} : Bool} -> (@+___14: Bool -> {Bq.census(Bq.hero_step_go(___14, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, arm_3, Fail{error_4}, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.mb(chm_5)))) : List<&2, Nat>})))))))))))))))}; apply_61(k_0, inv_1, wea_6, arm_7, error_12, chm_8, gold_9, lv_2, str_3, agi_4, vit_5, pts_10, ei_11, has_13, Bq.can_wear(k_0, lv_2, str_3, agi_4, vit_5))))); \{}}})))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@+wea_6: Bq.Maybe(Nat) -> (@+arm_7: Bq.Maybe(Nat) -> (@+chm_8: Bq.Maybe(Nat) -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_65 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_65(Bq.item_info(k_0))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> (@+__13: {Bq.Bag.le(Bq.one(k_0), inv_1) == True{} : Bool} -> {Bq.census(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le((apply_66 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_66(Bq.item_info(k_0))), lv_2), Bq.Bool.and(Bq.Nat.le((apply_67 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_67(Bq.item_info(k_0))), str_3), Bq.Bool.and(Bq.Nat.le((apply_68 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_68(Bq.item_info(k_0))), agi_4), Bq.Nat.le((apply_69 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_69(Bq.item_info(k_0))), vit_5))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_6, arm_7, ___12, chm_8, gold_9, lv_2, str_3, agi_4, vit_5, pts_10})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_6), Bq.Bag.add(Bq.mb(arm_7), Bq.Bag.add(Bq.mb(___12), Bq.mb(chm_8))))) : List<&2, Nat>}))))))))))))))}; apply_60(k_0, inv_1, lv_3, str_4, agi_5, vit_6, wea_7, arm_8, chm_9, gold_10, pts_11, ei_12, hel_2)); \{}}}))))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+hel_2: Bq.Maybe(Nat) -> (@+lv_3: Nat -> (@+str_4: Nat -> (@+agi_5: Nat -> (@+vit_6: Nat -> (@+wea_7: Bq.Maybe(Nat) -> (@+arm_8: Bq.Maybe(Nat) -> (@+chm_9: Bq.Maybe(Nat) -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_70 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_70(Bq.item_info(k_0))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+___13: Bool -> (@+_e_14: {Bq.Bag.le(Bq.one(k_0), inv_1) == ___13 : Bool} -> {Bq.census(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(hel_2), Bq.Bool.and(Bq.Nat.le((apply_71 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_71(Bq.item_info(k_0))), lv_3), Bq.Bool.and(Bq.Nat.le((apply_72 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_72(Bq.item_info(k_0))), str_4), Bq.Bool.and(Bq.Nat.le((apply_73 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_73(Bq.item_info(k_0))), agi_5), Bq.Nat.le((apply_74 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_74(Bq.item_info(k_0))), vit_6)))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_7, arm_8, hel_2, chm_9, gold_10, lv_3, str_4, agi_5, vit_6, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_7), Bq.Bag.add(Bq.mb(arm_8), Bq.Bag.add(Bq.mb(hel_2), Bq.mb(chm_9))))) : List<&2, Nat>})))))))))))))))}; apply_59(k_0, inv_1, hel_4, lv_7, str_8, agi_9, vit_10, wea_2, arm_3, chm_5, gold_6, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_1), {==}))); \{Bq.ISlot.SlotC: (ei_12 => (apply_75 = {(k_0 => (inv_1 => (chm_2 => (lv_3 => (str_4 => (agi_5 => (vit_6 => (wea_7 => (arm_8 => (hel_9 => (gold_10 => (pts_11 => (ei_12 => \{False: (has_13 => {==}); \{True: (apply_76 = {(k_0 => (inv_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (wea_6 => (arm_7 => (hel_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => (has_13 => {==})); \{Fail: (error_12 => (has_13 => (apply_77 = {(k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (error_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (ei_12 => (has_13 => \{False: {==}; \{True: (%Equal.sym(Bq.ISlot, (apply_78 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_78(Bq.item_info(k_0))), Bq.ISlot.SlotC{}, ei_12) : {Bq.census((apply_79 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_79(inv_1, k_0, arm_3, hel_4, Fail{error_5}, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, wea_2, _))) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.Bag.add(Bq.mb(hel_4), Nil{})))) : List<&2, Nat>}; Bq.equip_shuffle_chm(inv_1, Bq.one(k_0), Bq.mb(wea_2), Bq.mb(arm_3), Bq.mb(hel_4), has_13)); \{}}})))))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+wea_2: Bq.Maybe(Nat) -> (@+arm_3: Bq.Maybe(Nat) -> (@+hel_4: Bq.Maybe(Nat) -> (@-error_5: Unit -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_80 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_80(Bq.item_info(k_0))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+has_13: {Bq.Bag.le(Bq.one(k_0), inv_1) == True{} : Bool} -> (@+___14: Bool -> {Bq.census(Bq.hero_step_go(___14, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, arm_3, hel_4, Fail{error_5}, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.Bag.add(Bq.mb(hel_4), Nil{})))) : List<&2, Nat>})))))))))))))))}; apply_77(k_0, inv_1, wea_6, arm_7, hel_8, error_12, gold_9, lv_2, str_3, agi_4, vit_5, pts_10, ei_11, has_13, Bq.can_wear(k_0, lv_2, str_3, agi_4, vit_5))))); \{}}})))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@+wea_6: Bq.Maybe(Nat) -> (@+arm_7: Bq.Maybe(Nat) -> (@+hel_8: Bq.Maybe(Nat) -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_81 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_81(Bq.item_info(k_0))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> (@+__13: {Bq.Bag.le(Bq.one(k_0), inv_1) == True{} : Bool} -> {Bq.census(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le((apply_82 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_82(Bq.item_info(k_0))), lv_2), Bq.Bool.and(Bq.Nat.le((apply_83 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_83(Bq.item_info(k_0))), str_3), Bq.Bool.and(Bq.Nat.le((apply_84 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_84(Bq.item_info(k_0))), agi_4), Bq.Nat.le((apply_85 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_85(Bq.item_info(k_0))), vit_5))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_6, arm_7, hel_8, ___12, gold_9, lv_2, str_3, agi_4, vit_5, pts_10})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_6), Bq.Bag.add(Bq.mb(arm_7), Bq.Bag.add(Bq.mb(hel_8), Bq.mb(___12))))) : List<&2, Nat>}))))))))))))))}; apply_76(k_0, inv_1, lv_3, str_4, agi_5, vit_6, wea_7, arm_8, hel_9, gold_10, pts_11, ei_12, chm_2)); \{}}}))))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+chm_2: Bq.Maybe(Nat) -> (@+lv_3: Nat -> (@+str_4: Nat -> (@+agi_5: Nat -> (@+vit_6: Nat -> (@+wea_7: Bq.Maybe(Nat) -> (@+arm_8: Bq.Maybe(Nat) -> (@+hel_9: Bq.Maybe(Nat) -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_86 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_86(Bq.item_info(k_0))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+___13: Bool -> (@+_e_14: {Bq.Bag.le(Bq.one(k_0), inv_1) == ___13 : Bool} -> {Bq.census(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(chm_2), Bq.Bool.and(Bq.Nat.le((apply_87 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_87(Bq.item_info(k_0))), lv_3), Bq.Bool.and(Bq.Nat.le((apply_88 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_88(Bq.item_info(k_0))), str_4), Bq.Bool.and(Bq.Nat.le((apply_89 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_89(Bq.item_info(k_0))), agi_5), Bq.Nat.le((apply_90 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_90(Bq.item_info(k_0))), vit_6)))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_7, arm_8, hel_9, chm_2, gold_10, lv_3, str_4, agi_5, vit_6, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_7), Bq.Bag.add(Bq.mb(arm_8), Bq.Bag.add(Bq.mb(hel_9), Bq.mb(chm_2))))) : List<&2, Nat>})))))))))))))))}; apply_75(k_0, inv_1, chm_5, lv_7, str_8, agi_9, vit_10, wea_2, arm_3, hel_4, gold_6, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_1), {==}))); \{}}}}}})))))))))))) : (@+k_0: Nat -> (@+inv_1: Bq.Bag -> (@+wea_2: Bq.Maybe(Nat) -> (@+arm_3: Bq.Maybe(Nat) -> (@+hel_4: Bq.Maybe(Nat) -> (@+chm_5: Bq.Maybe(Nat) -> (@-gold_6: Nat -> (@+lv_7: Nat -> (@+str_8: Nat -> (@+agi_9: Nat -> (@+vit_10: Nat -> (@-pts_11: Nat -> (@+___12: Bq.ISlot -> (@+_e_13: {(apply_91 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_91(Bq.item_info(k_0))) == ___12 : Bq.ISlot} -> {Bq.census(Bq.hero_step_go((apply_92 = {(k_0 => (h_1 => \{Bq.ISlot.SlotNone: False{}; \{Bq.ISlot.SlotW: (apply_93 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(wea_2), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_93(k_0, h_1)); \{Bq.ISlot.SlotA: (apply_94 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(arm_3), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_94(k_0, h_1)); \{Bq.ISlot.SlotH: (apply_95 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(hel_4), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_95(k_0, h_1)); \{Bq.ISlot.SlotC: (apply_96 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(chm_5), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_96(k_0, h_1)); \{}}}}}})) : (@+k_0: Nat -> (@+h_1: Bq.Hero -> (@+___2: Bq.ISlot -> Bool)))}; apply_92(k_0, Bq.Hero.Hero{inv_1, wea_2, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11}, ___12)), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Bag.add(inv_1, Bq.Bag.add(Bq.mb(wea_2), Bq.Bag.add(Bq.mb(arm_3), Bq.Bag.add(Bq.mb(hel_4), Bq.mb(chm_5))))) : List<&2, Nat>}))))))))))))))}; apply_26(k_0, field_199, field_200, field_201, field_202, field_203, field_204, field_205, field_206, field_207, field_208, field_209, Bq.islot(k_0), {==}))

law Bq.unequip_shuffle:
  (@+i_0: Bq.Bag -> (@+k1_1: Bq.Bag -> (@+r_2: Bq.Bag -> {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), r_2) == Bq.Bag.add(i_0, Bq.Bag.add(k1_1, r_2)) : Bq.Bag})))

def Bq.unequip_shuffle(i_0, k1_1, r_2):
  (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.Bag.add(k1_1, i_0), r_2), Bq.Bag.add(k1_1, Bq.Bag.add(i_0, r_2)), Bq.Bag.add_assoc(k1_1, i_0, r_2)) : {_ == Bq.Bag.add(i_0, Bq.Bag.add(k1_1, r_2)) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(k1_1, Bq.Bag.add(i_0, r_2)), Bq.Bag.add(i_0, Bq.Bag.add(k1_1, r_2)), Bq.bag_swap(k1_1, i_0, r_2)) : {_ == Bq.Bag.add(i_0, Bq.Bag.add(k1_1, r_2)) : List<&2, Nat>}; {==}))

law Bq.unequip_shuffle2:
  (@+i_0: Bq.Bag -> (@+k1_1: Bq.Bag -> (@+w_2: Bq.Bag -> (@+g_3: Bq.Bag -> {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, g_3)) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(k1_1, g_3))) : Bq.Bag}))))

def Bq.unequip_shuffle2(i_0, k1_1, w_2, g_3):
  (%Equal.sym(Bq.Bag, Bq.Bag.add(w_2, Bq.Bag.add(k1_1, g_3)), Bq.Bag.add(k1_1, Bq.Bag.add(w_2, g_3)), Bq.bag_swap(w_2, k1_1, g_3)) : {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, g_3)) == Bq.Bag.add(i_0, _) : List<&2, Nat>}; Bq.unequip_shuffle(i_0, k1_1, Bq.Bag.add(w_2, g_3)))

law Bq.unequip_shuffle3:
  (@+i_0: Bq.Bag -> (@+k1_1: Bq.Bag -> (@+w_2: Bq.Bag -> (@+a_3: Bq.Bag -> (@+g_4: Bq.Bag -> {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, Bq.Bag.add(a_3, g_4))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, Bq.Bag.add(k1_1, g_4)))) : Bq.Bag})))))

def Bq.unequip_shuffle3(i_0, k1_1, w_2, a_3, g_4):
  (%Equal.sym(Bq.Bag, Bq.Bag.add(a_3, Bq.Bag.add(k1_1, g_4)), Bq.Bag.add(k1_1, Bq.Bag.add(a_3, g_4)), Bq.bag_swap(a_3, k1_1, g_4)) : {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, Bq.Bag.add(a_3, g_4))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, _)) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(w_2, Bq.Bag.add(k1_1, Bq.Bag.add(a_3, g_4))), Bq.Bag.add(k1_1, Bq.Bag.add(w_2, Bq.Bag.add(a_3, g_4))), Bq.bag_swap(w_2, k1_1, Bq.Bag.add(a_3, g_4))) : {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, Bq.Bag.add(a_3, g_4))) == Bq.Bag.add(i_0, _) : List<&2, Nat>}; Bq.unequip_shuffle(i_0, k1_1, Bq.Bag.add(w_2, Bq.Bag.add(a_3, g_4)))))

law Bq.unequip_shuffle4:
  (@+i_0: Bq.Bag -> (@+k1_1: Bq.Bag -> (@+w_2: Bq.Bag -> (@+a_3: Bq.Bag -> (@+hb_4: Bq.Bag -> {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, Bq.Bag.add(a_3, Bq.Bag.add(hb_4, Nil{})))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, Bq.Bag.add(hb_4, k1_1)))) : Bq.Bag})))))

def Bq.unequip_shuffle4(i_0, k1_1, w_2, a_3, hb_4):
  (%Equal.sym(Bq.Bag, Bq.Bag.add(hb_4, Nil{}), hb_4, Bq.Bag.add_nil(hb_4)) : {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, Bq.Bag.add(a_3, _))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, Bq.Bag.add(hb_4, k1_1)))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(hb_4, k1_1), Bq.Bag.add(k1_1, hb_4), Bq.Bag.add_comm(hb_4, k1_1)) : {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, Bq.Bag.add(a_3, _))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(a_3, Bq.Bag.add(k1_1, hb_4)), Bq.Bag.add(k1_1, Bq.Bag.add(a_3, hb_4)), Bq.bag_swap(a_3, k1_1, hb_4)) : {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4))) == Bq.Bag.add(i_0, Bq.Bag.add(w_2, _)) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(w_2, Bq.Bag.add(k1_1, Bq.Bag.add(a_3, hb_4))), Bq.Bag.add(k1_1, Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4))), Bq.bag_swap(w_2, k1_1, Bq.Bag.add(a_3, hb_4))) : {Bq.Bag.add(Bq.Bag.add(k1_1, i_0), Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4))) == Bq.Bag.add(i_0, _) : List<&2, Nat>}; Bq.unequip_shuffle(i_0, k1_1, Bq.Bag.add(w_2, Bq.Bag.add(a_3, hb_4)))))))

law Bq.unequip_preserves_census:
  (@+s_0: Bq.ISlot -> (@+h_1: Bq.Hero -> {Bq.census(Bq.hero_step(Bq.HOp.Unequip{s_0}, h_1)) == Bq.census(h_1) : Bq.Bag}))

def Bq.unequip_preserves_census(s_0, h_1):
  match h_1:
    case Bq.Hero.Hero{field_210, field_211, field_212, field_213, field_214, field_215, field_216, field_217, field_218, field_219, field_220}:
      (apply_97 = {\{Bq.ISlot.SlotNone: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==}))))))))))); \{Bq.ISlot.SlotW: (inv_0 => \{Fail: (u_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==})))))))))); \{Done: (k0_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.unequip_shuffle(inv_0, Bq.one(k0_1), Bq.Bag.add(Bq.mb(arm_2), Bq.Bag.add(Bq.mb(hel_3), Bq.mb(chm_4)))))))))))))); \{}}}); \{Bq.ISlot.SlotA: (inv_0 => (wea_1 => \{Fail: (u_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==}))))))))); \{Done: (k0_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.unequip_shuffle2(inv_0, Bq.one(k0_2), Bq.mb(wea_1), Bq.Bag.add(Bq.mb(hel_3), Bq.mb(chm_4)))))))))))); \{}}})); \{Bq.ISlot.SlotH: (inv_0 => (wea_1 => (arm_2 => \{Fail: (u_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==})))))))); \{Done: (k0_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.unequip_shuffle3(inv_0, Bq.one(k0_3), Bq.mb(wea_1), Bq.mb(arm_2), Bq.mb(chm_4)))))))))); \{}}}))); \{Bq.ISlot.SlotC: (inv_0 => (wea_1 => (arm_2 => (hel_3 => \{Fail: (u_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==}))))))); \{Done: (k0_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => Bq.unequip_shuffle4(inv_0, Bq.one(k0_4), Bq.mb(wea_1), Bq.mb(arm_2), Bq.mb(hel_3))))))))); \{}}})))); \{}}}}}} : (@+___0: Bq.ISlot -> (@+__1: List<&2, Nat> -> (@+__2: Result<&2, &2, Unit, Nat> -> (@+__3: Result<&2, &2, Unit, Nat> -> (@+__4: Result<&2, &2, Unit, Nat> -> (@+__5: Result<&2, &2, Unit, Nat> -> (@+__6: Nat -> (@+__7: Nat -> (@+__8: Nat -> (@+__9: Nat -> (@+__10: Nat -> (@+__11: Nat -> {Bq.census(Bq.hero_step_go(Bq.Bool.not(Bq.slot_empty(Bq.slot_of(Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11}, ___0))), Bq.HOp.Unequip{___0}, Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11})) == Bq.Bag.add(__1, Bq.Bag.add(Bq.mb(__2), Bq.Bag.add(Bq.mb(__3), Bq.Bag.add(Bq.mb(__4), Bq.mb(__5))))) : List<&2, Nat>}))))))))))))}; apply_97(s_0, field_210, field_211, field_212, field_213, field_214, field_215, field_216, field_217, field_218, field_219, field_220))

law Bq.transfer:
  (@+op_0: Bq.HOp -> Bool)

def Bq.transfer(op_0):
  match op_0:
    case Bq.HOp.Equip{field_221}:
      True{}
    case Bq.HOp.Unequip{field_222}:
      True{}
    case Bq.HOp.Buy{field_223}:
      False{}
    case Bq.HOp.Quaff{}:
      False{}
    case Bq.HOp.Alloc{field_224}:
      False{}
    case Bq.HOp.LevelUp{}:
      False{}

law Bq.transfers:
  (@+ops_0: List<&2, Bq.HOp> -> Bool)

def Bq.transfers(ops_0):
  match ops_0:
    case Nil{}:
      True{}
    case Con{field_225, field_226}:
      Bq.Bool.and(Bq.transfer(field_225), Bq.transfers(field_226))

law Bq.hero_run:
  (@+ops_0: List<&2, Bq.HOp> -> (@+h_1: Bq.Hero -> Bq.Hero))

def Bq.hero_run(ops_0, h_1):
  match ops_0:
    case Nil{}:
      h_1
    case Con{field_227, field_228}:
      Bq.hero_run(field_228, Bq.hero_step(field_227, h_1))

law Bq.transfers_preserve_census:
  (@+ops_0: List<&2, Bq.HOp> -> (@+__1: {Bq.transfers(ops_0) == True{} : Bool} -> (@+h_2: Bq.Hero -> {Bq.census(Bq.hero_run(ops_0, h_2)) == Bq.census(h_2) : Bq.Bag})))

def Bq.transfers_preserve_census(ops_0, __1, h_2):
  match ops_0:
    case Nil{}:
      {==}
    case Con{field_229, field_230}:
      match field_229:
        case Bq.HOp.Equip{field_231}:
          (%Equal.sym(Bq.Bag, Bq.census(Bq.hero_run(field_230, Bq.hero_step(Bq.HOp.Equip{field_231}, h_2))), Bq.census(Bq.hero_step(Bq.HOp.Equip{field_231}, h_2)), Bq.transfers_preserve_census(field_230, __1, Bq.hero_step(Bq.HOp.Equip{field_231}, h_2))) : {_ == Bq.census(h_2) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.census(Bq.hero_step(Bq.HOp.Equip{field_231}, h_2)), Bq.census(h_2), Bq.equip_preserves_census(field_231, h_2)) : {_ == Bq.census(h_2) : List<&2, Nat>}; {==}))
        case Bq.HOp.Unequip{field_232}:
          (%Equal.sym(Bq.Bag, Bq.census(Bq.hero_run(field_230, Bq.hero_step(Bq.HOp.Unequip{field_232}, h_2))), Bq.census(Bq.hero_step(Bq.HOp.Unequip{field_232}, h_2)), Bq.transfers_preserve_census(field_230, __1, Bq.hero_step(Bq.HOp.Unequip{field_232}, h_2))) : {_ == Bq.census(h_2) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.census(Bq.hero_step(Bq.HOp.Unequip{field_232}, h_2)), Bq.census(h_2), Bq.unequip_preserves_census(field_232, h_2)) : {_ == Bq.census(h_2) : List<&2, Nat>}; {==}))
        case Bq.HOp.Buy{field_233}:
          (apply_98 = {(rest_0 => (k_1 => (h_2 => \{}))) : (@-rest_0: List<&2, Bq.HOp> -> (@-k_1: Nat -> (@-h_2: Bq.Hero -> (@+___3: Empty -> {Bq.census(Bq.hero_run(rest_0, Bq.hero_step_go(Bq.Bool.and(Bq.Nat.le(1n, (apply_99 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => price_7)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_99(Bq.item_info(k_1)))), Bq.Nat.le((apply_100 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => price_7)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_100(Bq.item_info(k_1))), Bq.hero_gold(h_2))), Bq.HOp.Buy{k_1}, h_2))) == Bq.census(h_2) : List<&2, Nat>}))))}; apply_98(field_230, field_233, h_2, Bq.Bool.false_ne_true(__1)))
        case Bq.HOp.Quaff{}:
          (apply_101 = {(rest_0 => (h_1 => \{})) : (@-rest_0: List<&2, Bq.HOp> -> (@-h_1: Bq.Hero -> (@+___2: Empty -> {Bq.census(Bq.hero_run(rest_0, Bq.hero_step_go(Bq.quaff_ok(h_1), Bq.HOp.Quaff{}, h_1))) == Bq.census(h_1) : List<&2, Nat>})))}; apply_101(field_230, h_2, Bq.Bool.false_ne_true(__1)))
        case Bq.HOp.Alloc{field_234}:
          (apply_102 = {(rest_0 => (h_1 => (s_2 => \{}))) : (@-rest_0: List<&2, Bq.HOp> -> (@-h_1: Bq.Hero -> (@-s_2: Nat -> (@+___3: Empty -> {Bq.census(Bq.hero_run(rest_0, Bq.hero_step_go(Bq.alloc_ok(h_1), Bq.HOp.Alloc{s_2}, h_1))) == Bq.census(h_1) : List<&2, Nat>}))))}; apply_102(field_230, h_2, field_234, Bq.Bool.false_ne_true(__1)))
        case Bq.HOp.LevelUp{}:
          (apply_103 = {(rest_0 => (h_1 => \{})) : (@-rest_0: List<&2, Bq.HOp> -> (@-h_1: Bq.Hero -> (@+___2: Empty -> {Bq.census(Bq.hero_run(rest_0, Bq.do_levelup(h_1))) == Bq.census(h_1) : List<&2, Nat>})))}; apply_103(field_230, h_2, Bq.Bool.false_ne_true(__1)))

law Bq.buy_mints_exactly_one:
  (@+k_0: Nat -> (@+h_1: Bq.Hero -> (@+__2: {Bq.buy_ok(k_0, h_1) == True{} : Bool} -> {Bq.census(Bq.hero_step(Bq.HOp.Buy{k_0}, h_1)) == Bq.Bag.add(Bq.one(k_0), Bq.census(h_1)) : Bq.Bag})))

def Bq.buy_mints_exactly_one(k_0, h_1, __2):
  match h_1:
    case Bq.Hero.Hero{field_235, field_236, field_237, field_238, field_239, field_240, field_241, field_242, field_243, field_244, field_245}:
      (%Equal.sym(Bool, Bq.buy_ok(k_0, Bq.Hero.Hero{field_235, field_236, field_237, field_238, field_239, field_240, field_241, field_242, field_243, field_244, field_245}), True{}, __2) : {Bq.census(Bq.hero_step_go(_, Bq.HOp.Buy{k_0}, Bq.Hero.Hero{field_235, field_236, field_237, field_238, field_239, field_240, field_241, field_242, field_243, field_244, field_245})) == Bq.Bag.add(Bq.one(k_0), Bq.Bag.add(field_235, Bq.Bag.add(Bq.mb(field_236), Bq.Bag.add(Bq.mb(field_237), Bq.Bag.add(Bq.mb(field_238), Bq.mb(field_239)))))) : List<&2, Nat>}; Bq.Bag.add_assoc(Bq.one(k_0), field_235, Bq.gear_bag(field_236, field_237, field_238, field_239)))

law Bq.buy_burns_exact_gold:
  (@+k_0: Nat -> (@+h_1: Bq.Hero -> (@+__2: {Bq.buy_ok(k_0, h_1) == True{} : Bool} -> {Bq.Nat.add(Bq.iprice(k_0), Bq.hero_gold(Bq.hero_step(Bq.HOp.Buy{k_0}, h_1))) == Bq.hero_gold(h_1) : Nat})))

def Bq.buy_burns_exact_gold(k_0, h_1, __2):
  match h_1:
    case Bq.Hero.Hero{field_246, field_247, field_248, field_249, field_250, field_251, field_252, field_253, field_254, field_255, field_256}:
      (+ev_13 = Bq.Bool.and_r(Bq.Nat.lt(0n, Bq.iprice(k_0)), Bq.Nat.le(Bq.iprice(k_0), field_251), __2); (%Equal.sym(Bool, Bq.buy_ok(k_0, Bq.Hero.Hero{field_246, field_247, field_248, field_249, field_250, field_251, field_252, field_253, field_254, field_255, field_256}), True{}, __2) : {Bq.Nat.add((apply_104 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => price_7)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_104(Bq.item_info(k_0))), Bq.hero_gold(Bq.hero_step_go(_, Bq.HOp.Buy{k_0}, Bq.Hero.Hero{field_246, field_247, field_248, field_249, field_250, field_251, field_252, field_253, field_254, field_255, field_256}))) == field_251 : Nat}; Bq.Nat.add_sub_cancel(Bq.iprice(k_0), field_251, ev_13)))

law Bq.and_intro:
  (@+x_0: Bool -> (@+y_1: Bool -> (@+ex_2: {x_0 == True{} : Bool} -> (@+ey_3: {y_1 == True{} : Bool} -> {Bq.Bool.and(x_0, y_1) == True{} : Bool}))))

def Bq.and_intro(x_0, y_1, ex_2, ey_3):
  (%Equal.sym(Bool, x_0, True{}, ex_2) : {Bq.Bool.and(_, y_1) == True{} : Bool}; (%Equal.sym(Bool, y_1, True{}, ey_3) : {_ == True{} : Bool}; {==}))

law Bq.shop_never_refuses_a_funded_buy:
  (@+k_0: Nat -> (@+__1: {Bq.Nat.lt(0n, Bq.iprice(k_0)) == True{} : Bool} -> (@+h_2: Bq.Hero -> (@+__3: {Bq.Nat.le(Bq.iprice(k_0), Bq.hero_gold(h_2)) == True{} : Bool} -> {Bq.census(Bq.hero_step(Bq.HOp.Buy{k_0}, h_2)) == Bq.Bag.add(Bq.one(k_0), Bq.census(h_2)) : Bq.Bag}))))

def Bq.shop_never_refuses_a_funded_buy(k_0, __1, h_2, __3):
  Bq.buy_mints_exactly_one(k_0, h_2, Bq.and_intro(Bq.Nat.lt(0n, Bq.iprice(k_0)), Bq.Nat.le(Bq.iprice(k_0), Bq.hero_gold(h_2)), __1, __3))

law Bq.quaff_burns_one_potion:
  (@+h_0: Bq.Hero -> (@+__1: {Bq.quaff_ok(h_0) == True{} : Bool} -> {Bq.Bag.add(Bq.one(Bq.POTION), Bq.census(Bq.hero_step(Bq.HOp.Quaff{}, h_0))) == Bq.census(h_0) : Bq.Bag}))

def Bq.quaff_burns_one_potion(h_0, __1):
  match h_0:
    case Bq.Hero.Hero{field_257, field_258, field_259, field_260, field_261, field_262, field_263, field_264, field_265, field_266, field_267}:
      (apply_105 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (e_11 => \{True: (has_12 => (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.one(0n), Bq.Bag.add(Bq.Bag.sub(inv_0, Bq.one(0n)), Bq.gear_bag(wea_1, arm_2, hel_3, chm_4))), Bq.Bag.add(Bq.Bag.add(Bq.one(0n), Bq.Bag.sub(inv_0, Bq.one(0n))), Bq.gear_bag(wea_1, arm_2, hel_3, chm_4)), Equal.sym(Bq.Bag, Bq.Bag.add(Bq.Bag.add(Bq.one(0n), Bq.Bag.sub(inv_0, Bq.one(0n))), Bq.gear_bag(wea_1, arm_2, hel_3, chm_4)), Bq.Bag.add(Bq.one(0n), Bq.Bag.add(Bq.Bag.sub(inv_0, Bq.one(0n)), Bq.gear_bag(wea_1, arm_2, hel_3, chm_4))), Bq.Bag.add_assoc(Bq.one(0n), Bq.Bag.sub(inv_0, Bq.one(0n)), Bq.gear_bag(wea_1, arm_2, hel_3, chm_4)))) : {_ == Bq.Bag.add(inv_0, Bq.Bag.add(Bq.mb(wea_1), Bq.Bag.add(Bq.mb(arm_2), Bq.Bag.add(Bq.mb(hel_3), Bq.mb(chm_4))))) : List<&2, Nat>}; (%Equal.sym(Bq.Bag, Bq.Bag.add(Bq.one(0n), Bq.Bag.sub(inv_0, Bq.one(0n))), inv_0, Bq.Bag.add_sub_cancel(Bq.one(0n), inv_0, has_12)) : {Bq.Bag.add(_, Bq.Bag.add(Bq.mb(wea_1), Bq.Bag.add(Bq.mb(arm_2), Bq.Bag.add(Bq.mb(hel_3), Bq.mb(chm_4))))) == Bq.Bag.add(inv_0, Bq.Bag.add(Bq.mb(wea_1), Bq.Bag.add(Bq.mb(arm_2), Bq.Bag.add(Bq.mb(hel_3), Bq.mb(chm_4))))) : List<&2, Nat>}; {==}))); \{False: (has_12 => (apply_106 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => \{}))))) : (@-inv_0: Bq.Bag -> (@-wea_1: Bq.Maybe(Nat) -> (@-arm_2: Bq.Maybe(Nat) -> (@-hel_3: Bq.Maybe(Nat) -> (@-chm_4: Bq.Maybe(Nat) -> (@+___5: Empty -> {Bq.Bag.add([1n], Bq.Bag.add(inv_0, Bq.Bag.add(Bq.mb(wea_1), Bq.Bag.add(Bq.mb(arm_2), Bq.Bag.add(Bq.mb(hel_3), Bq.mb(chm_4)))))) == Bq.Bag.add(inv_0, Bq.Bag.add(Bq.mb(wea_1), Bq.Bag.add(Bq.mb(arm_2), Bq.Bag.add(Bq.mb(hel_3), Bq.mb(chm_4))))) : List<&2, Nat>}))))))}; apply_106(inv_0, wea_1, arm_2, hel_3, chm_4, Bq.Bool.false_ne_true(Equal.trans(Bool, False{}, Bq.Bag.le([1n], inv_0), True{}, Equal.sym(Bool, Bq.Bag.le([1n], inv_0), False{}, has_12), e_11))))); \{}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@-gold_5: Nat -> (@-lv_6: Nat -> (@-str_7: Nat -> (@-agi_8: Nat -> (@-vit_9: Nat -> (@-pts_10: Nat -> (@+e_11: {Bq.quaff_ok(Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}) == True{} : Bool} -> (@+___12: Bool -> (@+_e_13: {Bq.Bag.le([1n], inv_0) == ___12 : Bool} -> {Bq.Bag.add([1n], Bq.census(Bq.hero_step_go(___12, Bq.HOp.Quaff{}, Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}))) == Bq.Bag.add(inv_0, Bq.Bag.add(Bq.mb(wea_1), Bq.Bag.add(Bq.mb(arm_2), Bq.Bag.add(Bq.mb(hel_3), Bq.mb(chm_4))))) : List<&2, Nat>}))))))))))))))}; apply_105(field_257, field_258, field_259, field_260, field_261, field_262, field_263, field_264, field_265, field_266, field_267, __1, Bq.Bag.le(Bq.one(Bq.POTION), field_257), {==}))

law Bq.stat_total:
  (@+h_0: Bq.Hero -> Nat)

def Bq.stat_total(h_0):
  match h_0:
    case Bq.Hero.Hero{field_268, field_269, field_270, field_271, field_272, field_273, field_274, field_275, field_276, field_277, field_278}:
      Bq.Nat.add(field_275, Bq.Nat.add(field_276, Bq.Nat.add(field_277, field_278)))

law Bq.stat_expect:
  (@+op_0: Bq.HOp -> (@+h_1: Bq.Hero -> Nat))

def Bq.stat_expect(op_0, h_1):
  match op_0:
    case Bq.HOp.LevelUp{}:
      Bq.Nat.add(3n, Bq.stat_total(h_1))
    case Bq.HOp.Equip{field_279}:
      Bq.stat_total(h_1)
    case Bq.HOp.Unequip{field_280}:
      Bq.stat_total(h_1)
    case Bq.HOp.Buy{field_281}:
      Bq.stat_total(h_1)
    case Bq.HOp.Quaff{}:
      Bq.stat_total(h_1)
    case Bq.HOp.Alloc{field_282}:
      Bq.stat_total(h_1)

law Bq.stat_succ:
  (@+a_0: Nat -> (@+b_1: Nat -> (@+c_2: Nat -> (@+d_3: Nat -> {Bq.Nat.add(a_0, Bq.Nat.add(b_1, Bq.Nat.add(c_2, Succ{d_3}))) == Succ{Bq.Nat.add(a_0, Bq.Nat.add(b_1, Bq.Nat.add(c_2, d_3)))} : Nat}))))

def Bq.stat_succ(a_0, b_1, c_2, d_3):
  (%Equal.sym(Nat, Bq.Nat.add(c_2, Succ{d_3}), Succ{Bq.Nat.add(c_2, d_3)}, Bq.Nat.add_succ(c_2, d_3)) : {Bq.Nat.add(a_0, Bq.Nat.add(b_1, _)) == Succ{Bq.Nat.add(a_0, Bq.Nat.add(b_1, Bq.Nat.add(c_2, d_3)))} : Nat}; (%Equal.sym(Nat, Bq.Nat.add(b_1, Succ{Bq.Nat.add(c_2, d_3)}), Succ{Bq.Nat.add(b_1, Bq.Nat.add(c_2, d_3))}, Bq.Nat.add_succ(b_1, Bq.Nat.add(c_2, d_3))) : {Bq.Nat.add(a_0, _) == Succ{Bq.Nat.add(a_0, Bq.Nat.add(b_1, Bq.Nat.add(c_2, d_3)))} : Nat}; (%Equal.sym(Nat, Bq.Nat.add(a_0, Succ{Bq.Nat.add(b_1, Bq.Nat.add(c_2, d_3))}), Succ{Bq.Nat.add(a_0, Bq.Nat.add(b_1, Bq.Nat.add(c_2, d_3)))}, Bq.Nat.add_succ(a_0, Bq.Nat.add(b_1, Bq.Nat.add(c_2, d_3)))) : {_ == Succ{Bq.Nat.add(a_0, Bq.Nat.add(b_1, Bq.Nat.add(c_2, d_3)))} : Nat}; {==})))

law Bq.ops_respect_stat_budget:
  (@+op_0: Bq.HOp -> (@+h_1: Bq.Hero -> {Bq.stat_total(Bq.hero_step(op_0, h_1)) == Bq.stat_expect(op_0, h_1) : Nat}))

def Bq.ops_respect_stat_budget(op_0, h_1):
  match h_1:
    case Bq.Hero.Hero{field_283, field_284, field_285, field_286, field_287, field_288, field_289, field_290, field_291, field_292, field_293}:
      (apply_107 = {\{Bq.HOp.Equip: (k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (apply_108 = {(k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => \{Bq.ISlot.SlotNone: (ei_12 => {==}); \{Bq.ISlot.SlotW: (ei_12 => (apply_109 = {(wea_0 => (k_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (inv_6 => (arm_7 => (hel_8 => (chm_9 => (gold_10 => (pts_11 => (ei_12 => \{False: {==}; \{True: (apply_110 = {(k_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (inv_5 => (arm_6 => (hel_7 => (chm_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => {==}); \{Fail: (error_12 => (apply_111 = {(k_0 => (inv_1 => (error_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (ei_12 => \{False: {==}; \{True: (%Equal.sym(Bq.ISlot, (apply_112 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_112(Bq.item_info(k_0))), Bq.ISlot.SlotW{}, ei_12) : {Bq.stat_total((apply_113 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_113(inv_1, k_0, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, Fail{error_2}, _))) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}; {==}); \{}}}))))))))))))) : (@-k_0: Nat -> (@-inv_1: List<&2, Nat> -> (@-error_2: Unit -> (@-arm_3: Result<&2, &2, Unit, Nat> -> (@-hel_4: Result<&2, &2, Unit, Nat> -> (@-chm_5: Result<&2, &2, Unit, Nat> -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_114 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_114(Bq.item_info(k_0))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+___13: Bool -> {Bq.stat_total(Bq.hero_step_go(___13, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, Fail{error_2}, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}))))))))))))))}; apply_111(k_0, inv_5, error_12, arm_6, hel_7, chm_8, gold_9, lv_1, str_2, agi_3, vit_4, pts_10, ei_11, Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4)))); \{}}})))))))))))) : (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-inv_5: List<&2, Nat> -> (@-arm_6: Result<&2, &2, Unit, Nat> -> (@-hel_7: Result<&2, &2, Unit, Nat> -> (@-chm_8: Result<&2, &2, Unit, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_115 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_115(Bq.item_info(k_0))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le((apply_116 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_116(Bq.item_info(k_0))), lv_1), Bq.Bool.and(Bq.Nat.le((apply_117 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_117(Bq.item_info(k_0))), str_2), Bq.Bool.and(Bq.Nat.le((apply_118 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_118(Bq.item_info(k_0))), agi_3), Bq.Nat.le((apply_119 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_119(Bq.item_info(k_0))), vit_4))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_5, ___12, arm_6, hel_7, chm_8, gold_9, lv_1, str_2, agi_3, vit_4, pts_10})) == Bq.Nat.add(str_2, Bq.Nat.add(agi_3, Bq.Nat.add(vit_4, pts_10))) : Nat})))))))))))))}; apply_110(k_1, lv_2, str_3, agi_4, vit_5, inv_6, arm_7, hel_8, chm_9, gold_10, pts_11, ei_12, wea_0)); \{}}}))))))))))))) : (@+wea_0: Result<&2, &2, Unit, Nat> -> (@+k_1: Nat -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@-inv_6: List<&2, Nat> -> (@-arm_7: Result<&2, &2, Unit, Nat> -> (@-hel_8: Result<&2, &2, Unit, Nat> -> (@-chm_9: Result<&2, &2, Unit, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_120 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_120(Bq.item_info(k_1))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+___13: Bool -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(wea_0), Bq.Bool.and(Bq.Nat.le((apply_121 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_121(Bq.item_info(k_1))), lv_2), Bq.Bool.and(Bq.Nat.le((apply_122 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_122(Bq.item_info(k_1))), str_3), Bq.Bool.and(Bq.Nat.le((apply_123 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_123(Bq.item_info(k_1))), agi_4), Bq.Nat.le((apply_124 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_124(Bq.item_info(k_1))), vit_5)))))), Bq.HOp.Equip{k_1}, Bq.Hero.Hero{inv_6, wea_0, arm_7, hel_8, chm_9, gold_10, lv_2, str_3, agi_4, vit_5, pts_11})) == Bq.Nat.add(str_3, Bq.Nat.add(agi_4, Bq.Nat.add(vit_5, pts_11))) : Nat}))))))))))))))}; apply_109(wea_2, k_0, lv_7, str_8, agi_9, vit_10, inv_1, arm_3, hel_4, chm_5, gold_6, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_1)))); \{Bq.ISlot.SlotA: (ei_12 => (apply_125 = {(arm_0 => (k_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (inv_6 => (wea_7 => (hel_8 => (chm_9 => (gold_10 => (pts_11 => (ei_12 => \{False: {==}; \{True: (apply_126 = {(k_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (inv_5 => (wea_6 => (hel_7 => (chm_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => {==}); \{Fail: (error_12 => (apply_127 = {(k_0 => (inv_1 => (wea_2 => (error_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (ei_12 => \{False: {==}; \{True: (%Equal.sym(Bq.ISlot, (apply_128 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_128(Bq.item_info(k_0))), Bq.ISlot.SlotA{}, ei_12) : {Bq.stat_total((apply_129 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_129(inv_1, k_0, Fail{error_3}, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, wea_2, _))) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}; {==}); \{}}}))))))))))))) : (@-k_0: Nat -> (@-inv_1: List<&2, Nat> -> (@-wea_2: Result<&2, &2, Unit, Nat> -> (@-error_3: Unit -> (@-hel_4: Result<&2, &2, Unit, Nat> -> (@-chm_5: Result<&2, &2, Unit, Nat> -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_130 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_130(Bq.item_info(k_0))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+___13: Bool -> {Bq.stat_total(Bq.hero_step_go(___13, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, Fail{error_3}, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}))))))))))))))}; apply_127(k_0, inv_5, wea_6, error_12, hel_7, chm_8, gold_9, lv_1, str_2, agi_3, vit_4, pts_10, ei_11, Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4)))); \{}}})))))))))))) : (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-inv_5: List<&2, Nat> -> (@-wea_6: Result<&2, &2, Unit, Nat> -> (@-hel_7: Result<&2, &2, Unit, Nat> -> (@-chm_8: Result<&2, &2, Unit, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_131 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_131(Bq.item_info(k_0))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le((apply_132 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_132(Bq.item_info(k_0))), lv_1), Bq.Bool.and(Bq.Nat.le((apply_133 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_133(Bq.item_info(k_0))), str_2), Bq.Bool.and(Bq.Nat.le((apply_134 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_134(Bq.item_info(k_0))), agi_3), Bq.Nat.le((apply_135 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_135(Bq.item_info(k_0))), vit_4))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_5, wea_6, ___12, hel_7, chm_8, gold_9, lv_1, str_2, agi_3, vit_4, pts_10})) == Bq.Nat.add(str_2, Bq.Nat.add(agi_3, Bq.Nat.add(vit_4, pts_10))) : Nat})))))))))))))}; apply_126(k_1, lv_2, str_3, agi_4, vit_5, inv_6, wea_7, hel_8, chm_9, gold_10, pts_11, ei_12, arm_0)); \{}}}))))))))))))) : (@+arm_0: Result<&2, &2, Unit, Nat> -> (@+k_1: Nat -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@-inv_6: List<&2, Nat> -> (@-wea_7: Result<&2, &2, Unit, Nat> -> (@-hel_8: Result<&2, &2, Unit, Nat> -> (@-chm_9: Result<&2, &2, Unit, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_136 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_136(Bq.item_info(k_1))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+___13: Bool -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(arm_0), Bq.Bool.and(Bq.Nat.le((apply_137 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_137(Bq.item_info(k_1))), lv_2), Bq.Bool.and(Bq.Nat.le((apply_138 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_138(Bq.item_info(k_1))), str_3), Bq.Bool.and(Bq.Nat.le((apply_139 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_139(Bq.item_info(k_1))), agi_4), Bq.Nat.le((apply_140 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_140(Bq.item_info(k_1))), vit_5)))))), Bq.HOp.Equip{k_1}, Bq.Hero.Hero{inv_6, wea_7, arm_0, hel_8, chm_9, gold_10, lv_2, str_3, agi_4, vit_5, pts_11})) == Bq.Nat.add(str_3, Bq.Nat.add(agi_4, Bq.Nat.add(vit_5, pts_11))) : Nat}))))))))))))))}; apply_125(arm_3, k_0, lv_7, str_8, agi_9, vit_10, inv_1, wea_2, hel_4, chm_5, gold_6, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_1)))); \{Bq.ISlot.SlotH: (ei_12 => (apply_141 = {(hel_0 => (k_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (inv_6 => (wea_7 => (arm_8 => (chm_9 => (gold_10 => (pts_11 => (ei_12 => \{False: {==}; \{True: (apply_142 = {(k_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (inv_5 => (wea_6 => (arm_7 => (chm_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => {==}); \{Fail: (error_12 => (apply_143 = {(k_0 => (inv_1 => (wea_2 => (arm_3 => (error_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (ei_12 => \{False: {==}; \{True: (%Equal.sym(Bq.ISlot, (apply_144 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_144(Bq.item_info(k_0))), Bq.ISlot.SlotH{}, ei_12) : {Bq.stat_total((apply_145 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_145(inv_1, k_0, arm_3, Fail{error_4}, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, wea_2, _))) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}; {==}); \{}}}))))))))))))) : (@-k_0: Nat -> (@-inv_1: List<&2, Nat> -> (@-wea_2: Result<&2, &2, Unit, Nat> -> (@-arm_3: Result<&2, &2, Unit, Nat> -> (@-error_4: Unit -> (@-chm_5: Result<&2, &2, Unit, Nat> -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_146 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_146(Bq.item_info(k_0))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+___13: Bool -> {Bq.stat_total(Bq.hero_step_go(___13, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, arm_3, Fail{error_4}, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}))))))))))))))}; apply_143(k_0, inv_5, wea_6, arm_7, error_12, chm_8, gold_9, lv_1, str_2, agi_3, vit_4, pts_10, ei_11, Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4)))); \{}}})))))))))))) : (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-inv_5: List<&2, Nat> -> (@-wea_6: Result<&2, &2, Unit, Nat> -> (@-arm_7: Result<&2, &2, Unit, Nat> -> (@-chm_8: Result<&2, &2, Unit, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_147 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_147(Bq.item_info(k_0))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le((apply_148 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_148(Bq.item_info(k_0))), lv_1), Bq.Bool.and(Bq.Nat.le((apply_149 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_149(Bq.item_info(k_0))), str_2), Bq.Bool.and(Bq.Nat.le((apply_150 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_150(Bq.item_info(k_0))), agi_3), Bq.Nat.le((apply_151 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_151(Bq.item_info(k_0))), vit_4))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_5, wea_6, arm_7, ___12, chm_8, gold_9, lv_1, str_2, agi_3, vit_4, pts_10})) == Bq.Nat.add(str_2, Bq.Nat.add(agi_3, Bq.Nat.add(vit_4, pts_10))) : Nat})))))))))))))}; apply_142(k_1, lv_2, str_3, agi_4, vit_5, inv_6, wea_7, arm_8, chm_9, gold_10, pts_11, ei_12, hel_0)); \{}}}))))))))))))) : (@+hel_0: Result<&2, &2, Unit, Nat> -> (@+k_1: Nat -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@-inv_6: List<&2, Nat> -> (@-wea_7: Result<&2, &2, Unit, Nat> -> (@-arm_8: Result<&2, &2, Unit, Nat> -> (@-chm_9: Result<&2, &2, Unit, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_152 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_152(Bq.item_info(k_1))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+___13: Bool -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(hel_0), Bq.Bool.and(Bq.Nat.le((apply_153 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_153(Bq.item_info(k_1))), lv_2), Bq.Bool.and(Bq.Nat.le((apply_154 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_154(Bq.item_info(k_1))), str_3), Bq.Bool.and(Bq.Nat.le((apply_155 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_155(Bq.item_info(k_1))), agi_4), Bq.Nat.le((apply_156 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_156(Bq.item_info(k_1))), vit_5)))))), Bq.HOp.Equip{k_1}, Bq.Hero.Hero{inv_6, wea_7, arm_8, hel_0, chm_9, gold_10, lv_2, str_3, agi_4, vit_5, pts_11})) == Bq.Nat.add(str_3, Bq.Nat.add(agi_4, Bq.Nat.add(vit_5, pts_11))) : Nat}))))))))))))))}; apply_141(hel_4, k_0, lv_7, str_8, agi_9, vit_10, inv_1, wea_2, arm_3, chm_5, gold_6, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_1)))); \{Bq.ISlot.SlotC: (ei_12 => (apply_157 = {(chm_0 => (k_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (inv_6 => (wea_7 => (arm_8 => (hel_9 => (gold_10 => (pts_11 => (ei_12 => \{False: {==}; \{True: (apply_158 = {(k_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (inv_5 => (wea_6 => (arm_7 => (hel_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => {==}); \{Fail: (error_12 => (apply_159 = {(k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (error_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (ei_12 => \{False: {==}; \{True: (%Equal.sym(Bq.ISlot, (apply_160 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_160(Bq.item_info(k_0))), Bq.ISlot.SlotC{}, ei_12) : {Bq.stat_total((apply_161 = {(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))}; apply_161(inv_1, k_0, arm_3, hel_4, Fail{error_5}, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, wea_2, _))) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}; {==}); \{}}}))))))))))))) : (@-k_0: Nat -> (@-inv_1: List<&2, Nat> -> (@-wea_2: Result<&2, &2, Unit, Nat> -> (@-arm_3: Result<&2, &2, Unit, Nat> -> (@-hel_4: Result<&2, &2, Unit, Nat> -> (@-error_5: Unit -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_162 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_162(Bq.item_info(k_0))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+___13: Bool -> {Bq.stat_total(Bq.hero_step_go(___13, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, arm_3, hel_4, Fail{error_5}, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}))))))))))))))}; apply_159(k_0, inv_5, wea_6, arm_7, hel_8, error_12, gold_9, lv_1, str_2, agi_3, vit_4, pts_10, ei_11, Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4)))); \{}}})))))))))))) : (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-inv_5: List<&2, Nat> -> (@-wea_6: Result<&2, &2, Unit, Nat> -> (@-arm_7: Result<&2, &2, Unit, Nat> -> (@-hel_8: Result<&2, &2, Unit, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_163 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_163(Bq.item_info(k_0))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le((apply_164 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_164(Bq.item_info(k_0))), lv_1), Bq.Bool.and(Bq.Nat.le((apply_165 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_165(Bq.item_info(k_0))), str_2), Bq.Bool.and(Bq.Nat.le((apply_166 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_166(Bq.item_info(k_0))), agi_3), Bq.Nat.le((apply_167 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_167(Bq.item_info(k_0))), vit_4))))), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_5, wea_6, arm_7, hel_8, ___12, gold_9, lv_1, str_2, agi_3, vit_4, pts_10})) == Bq.Nat.add(str_2, Bq.Nat.add(agi_3, Bq.Nat.add(vit_4, pts_10))) : Nat})))))))))))))}; apply_158(k_1, lv_2, str_3, agi_4, vit_5, inv_6, wea_7, arm_8, hel_9, gold_10, pts_11, ei_12, chm_0)); \{}}}))))))))))))) : (@+chm_0: Result<&2, &2, Unit, Nat> -> (@+k_1: Nat -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@-inv_6: List<&2, Nat> -> (@-wea_7: Result<&2, &2, Unit, Nat> -> (@-arm_8: Result<&2, &2, Unit, Nat> -> (@-hel_9: Result<&2, &2, Unit, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_168 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_168(Bq.item_info(k_1))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+___13: Bool -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(chm_0), Bq.Bool.and(Bq.Nat.le((apply_169 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_169(Bq.item_info(k_1))), lv_2), Bq.Bool.and(Bq.Nat.le((apply_170 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_170(Bq.item_info(k_1))), str_3), Bq.Bool.and(Bq.Nat.le((apply_171 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_171(Bq.item_info(k_1))), agi_4), Bq.Nat.le((apply_172 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_172(Bq.item_info(k_1))), vit_5)))))), Bq.HOp.Equip{k_1}, Bq.Hero.Hero{inv_6, wea_7, arm_8, hel_9, chm_0, gold_10, lv_2, str_3, agi_4, vit_5, pts_11})) == Bq.Nat.add(str_3, Bq.Nat.add(agi_4, Bq.Nat.add(vit_5, pts_11))) : Nat}))))))))))))))}; apply_157(chm_5, k_0, lv_7, str_8, agi_9, vit_10, inv_1, wea_2, arm_3, hel_4, gold_6, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_1)))); \{}}}}}})))))))))))) : (@+k_0: Nat -> (@+inv_1: List<&2, Nat> -> (@+wea_2: Result<&2, &2, Unit, Nat> -> (@+arm_3: Result<&2, &2, Unit, Nat> -> (@+hel_4: Result<&2, &2, Unit, Nat> -> (@+chm_5: Result<&2, &2, Unit, Nat> -> (@-gold_6: Nat -> (@+lv_7: Nat -> (@+str_8: Nat -> (@+agi_9: Nat -> (@+vit_10: Nat -> (@-pts_11: Nat -> (@+___12: Bq.ISlot -> (@+_e_13: {(apply_173 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_173(Bq.item_info(k_0))) == ___12 : Bq.ISlot} -> {Bq.stat_total(Bq.hero_step_go((apply_174 = {(k_0 => (h_1 => \{Bq.ISlot.SlotNone: False{}; \{Bq.ISlot.SlotW: (apply_175 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(wea_2), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_175(k_0, h_1)); \{Bq.ISlot.SlotA: (apply_176 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(arm_3), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_176(k_0, h_1)); \{Bq.ISlot.SlotH: (apply_177 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(hel_4), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_177(k_0, h_1)); \{Bq.ISlot.SlotC: (apply_178 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(chm_5), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_178(k_0, h_1)); \{}}}}}})) : (@+k_0: Nat -> (@+h_1: Bq.Hero -> (@+___2: Bq.ISlot -> Bool)))}; apply_174(k_0, Bq.Hero.Hero{inv_1, wea_2, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11}, ___12)), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_1, wea_2, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat}))))))))))))))}; apply_108(k_0, inv_1, wea_2, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11, Bq.islot(k_0), {==})))))))))))))); \{Bq.HOp.Unequip: (s_0 => (apply_179 = {\{Bq.ISlot.SlotNone: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==}))))))))))); \{Bq.ISlot.SlotW: (inv_0 => \{Fail: (u_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==})))))))))); \{Done: (k0_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==})))))))))); \{}}}); \{Bq.ISlot.SlotA: (inv_0 => (wea_1 => \{Fail: (u_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==}))))))))); \{Done: (k0_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==}))))))))); \{}}})); \{Bq.ISlot.SlotH: (inv_0 => (wea_1 => (arm_2 => \{Fail: (u_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==})))))))); \{Done: (k0_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==})))))))); \{}}}))); \{Bq.ISlot.SlotC: (inv_0 => (wea_1 => (arm_2 => (hel_3 => \{Fail: (u_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==}))))))); \{Done: (k0_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => {==}))))))); \{}}})))); \{}}}}}} : (@+___0: Bq.ISlot -> (@+__1: List<&2, Nat> -> (@+__2: Result<&2, &2, Unit, Nat> -> (@+__3: Result<&2, &2, Unit, Nat> -> (@+__4: Result<&2, &2, Unit, Nat> -> (@+__5: Result<&2, &2, Unit, Nat> -> (@+__6: Nat -> (@+__7: Nat -> (@+__8: Nat -> (@+__9: Nat -> (@+__10: Nat -> (@+__11: Nat -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.not(Bq.slot_empty(Bq.slot_of(Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11}, ___0))), Bq.HOp.Unequip{___0}, Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11})) == Bq.Nat.add(__8, Bq.Nat.add(__9, Bq.Nat.add(__10, __11))) : Nat}))))))))))))}; apply_179(s_0))); \{Bq.HOp.Buy: (k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (apply_180 = {(k_0 => (gold_1 => (inv_2 => (wea_3 => (arm_4 => (hel_5 => (chm_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => \{False: {==}; \{True: (apply_181 = {(k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => \{False: {==}; \{True: {==}; \{}}})))))))))))) : (@-k_0: Nat -> (@-inv_1: List<&2, Nat> -> (@-wea_2: Result<&2, &2, Unit, Nat> -> (@-arm_3: Result<&2, &2, Unit, Nat> -> (@-hel_4: Result<&2, &2, Unit, Nat> -> (@-chm_5: Result<&2, &2, Unit, Nat> -> (@-gold_6: Nat -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+___12: Bool -> {Bq.stat_total(Bq.hero_step_go(___12, Bq.HOp.Buy{k_0}, Bq.Hero.Hero{inv_1, wea_2, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat})))))))))))))}; apply_181(k_0, inv_2, wea_3, arm_4, hel_5, chm_6, gold_1, lv_7, str_8, agi_9, vit_10, pts_11, Bq.Nat.le(Bq.iprice(k_0), gold_1))); \{}}})))))))))))) : (@+k_0: Nat -> (@+gold_1: Nat -> (@-inv_2: List<&2, Nat> -> (@-wea_3: Result<&2, &2, Unit, Nat> -> (@-arm_4: Result<&2, &2, Unit, Nat> -> (@-hel_5: Result<&2, &2, Unit, Nat> -> (@-chm_6: Result<&2, &2, Unit, Nat> -> (@-lv_7: Nat -> (@-str_8: Nat -> (@-agi_9: Nat -> (@-vit_10: Nat -> (@-pts_11: Nat -> (@+___12: Bool -> {Bq.stat_total(Bq.hero_step_go(Bq.Bool.and(___12, Bq.Nat.le((apply_182 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => price_7)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_182(Bq.item_info(k_0))), gold_1)), Bq.HOp.Buy{k_0}, Bq.Hero.Hero{inv_2, wea_3, arm_4, hel_5, chm_6, gold_1, lv_7, str_8, agi_9, vit_10, pts_11})) == Bq.Nat.add(str_8, Bq.Nat.add(agi_9, Bq.Nat.add(vit_10, pts_11))) : Nat})))))))))))))}; apply_180(k_0, gold_6, inv_1, wea_2, arm_3, hel_4, chm_5, lv_7, str_8, agi_9, vit_10, pts_11, Bq.Nat.lt(0n, Bq.iprice(k_0)))))))))))))))); \{Bq.HOp.Quaff: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (apply_183 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{False: {==}; \{True: {==}; \{}}}))))))))))) : (@-inv_0: List<&2, Nat> -> (@-wea_1: Result<&2, &2, Unit, Nat> -> (@-arm_2: Result<&2, &2, Unit, Nat> -> (@-hel_3: Result<&2, &2, Unit, Nat> -> (@-chm_4: Result<&2, &2, Unit, Nat> -> (@-gold_5: Nat -> (@-lv_6: Nat -> (@-str_7: Nat -> (@-agi_8: Nat -> (@-vit_9: Nat -> (@-pts_10: Nat -> (@+___11: Bool -> {Bq.stat_total(Bq.hero_step_go(___11, Bq.HOp.Quaff{}, Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10})) == Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, pts_10))) : Nat}))))))))))))}; apply_183(inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10, Bq.Bag.le(Bq.one(Bq.POTION), inv_0)))))))))))))); \{Bq.HOp.Alloc: (s_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => \{Zero: {==}; \{Succ: (field_184 => (apply_185 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => (%Equal.sym(Nat, Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{p_10}))), Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_10)))}, Bq.stat_succ(str_7, agi_8, vit_9, p_10)) : {Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_10)))} == _ : Nat}; {==})); \{Succ: (p_10 => (apply_186 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => (%Equal.sym(Nat, Bq.Nat.add(str_7, Succ{Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_10))}), Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_10)))}, Bq.Nat.add_succ(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_10)))) : {_ == Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{p_10}))) : Nat}; (%Equal.sym(Nat, Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{p_10}))), Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_10)))}, Bq.stat_succ(str_7, agi_8, vit_9, p_10)) : {Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_10)))} == _ : Nat}; {==}))); \{Succ: (p_10 => (p_11 => (%Equal.sym(Nat, Bq.Nat.add(agi_8, Succ{Bq.Nat.add(vit_9, p_11)}), Succ{Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_11))}, Bq.Nat.add_succ(agi_8, Bq.Nat.add(vit_9, p_11))) : {Bq.Nat.add(str_7, _) == Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{p_11}))) : Nat}; (%Equal.sym(Nat, Bq.Nat.add(str_7, Succ{Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_11))}), Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_11)))}, Bq.Nat.add_succ(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_11)))) : {_ == Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{p_11}))) : Nat}; (%Equal.sym(Nat, Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{p_11}))), Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_11)))}, Bq.stat_succ(str_7, agi_8, vit_9, p_11)) : {Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, p_11)))} == _ : Nat}; {==}))))); \{}}})))))))))) : (@-inv_0: List<&2, Nat> -> (@-wea_1: Result<&2, &2, Unit, Nat> -> (@-arm_2: Result<&2, &2, Unit, Nat> -> (@-hel_3: Result<&2, &2, Unit, Nat> -> (@-chm_4: Result<&2, &2, Unit, Nat> -> (@-gold_5: Nat -> (@-lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> {Bq.stat_total((apply_187 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, Succ{agi_8}, vit_9, p_10}); \{Succ: (p_10 => (p_11 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, Succ{vit_9}, p_11})); \{}}})))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))}; apply_187(inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, ___10, __11))) == Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{__11}))) : Nat}))))))))))))}; apply_186(inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, p_10))); \{}}})))))))))) : (@-inv_0: List<&2, Nat> -> (@-wea_1: Result<&2, &2, Unit, Nat> -> (@-arm_2: Result<&2, &2, Unit, Nat> -> (@-hel_3: Result<&2, &2, Unit, Nat> -> (@-chm_4: Result<&2, &2, Unit, Nat> -> (@-gold_5: Nat -> (@-lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> {Bq.stat_total((apply_188 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, Succ{str_7}, agi_8, vit_9, p_10}); \{Succ: (p_10 => (apply_189 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, Succ{agi_8}, vit_9, p_10}); \{Succ: (p_10 => (p_11 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, Succ{vit_9}, p_11})); \{}}})))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))}; apply_189(inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, p_10))); \{}}})))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))}; apply_188(inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, ___10, __11))) == Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{__11}))) : Nat}))))))))))))}; apply_185(inv_1, wea_2, arm_3, hel_4, chm_5, gold_6, lv_7, str_8, agi_9, vit_10, s_0, field_184))); \{}}}))))))))))); \{Bq.HOp.LevelUp: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (%Equal.sym(Nat, Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{Succ{Succ{pts_10}}}))), Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{Succ{pts_10}})))}, Bq.stat_succ(str_7, agi_8, vit_9, Succ{Succ{pts_10}})) : {_ == Succ{Succ{Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, pts_10)))}}} : Nat}; (%Equal.sym(Nat, Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{Succ{pts_10}}))), Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{pts_10})))}, Bq.stat_succ(str_7, agi_8, vit_9, Succ{pts_10})) : {Succ{_} == Succ{Succ{Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, pts_10)))}}} : Nat}; (%Equal.sym(Nat, Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, Succ{pts_10}))), Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, pts_10)))}, Bq.stat_succ(str_7, agi_8, vit_9, pts_10)) : {Succ{Succ{_}} == Succ{Succ{Succ{Bq.Nat.add(str_7, Bq.Nat.add(agi_8, Bq.Nat.add(vit_9, pts_10)))}}} : Nat}; {==})))))))))))))); \{}}}}}}} : (@+___0: Bq.HOp -> (@+__1: List<&2, Nat> -> (@+__2: Result<&2, &2, Unit, Nat> -> (@+__3: Result<&2, &2, Unit, Nat> -> (@+__4: Result<&2, &2, Unit, Nat> -> (@+__5: Result<&2, &2, Unit, Nat> -> (@+__6: Nat -> (@+__7: Nat -> (@+__8: Nat -> (@+__9: Nat -> (@+__10: Nat -> (@+__11: Nat -> {Bq.stat_total(Bq.hero_step_go(Bq.hop_ok(___0, Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11}), ___0, Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11})) == Bq.stat_expect(___0, Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11}) : Nat}))))))))))))}; apply_107(op_0, field_283, field_284, field_285, field_286, field_287, field_288, field_289, field_290, field_291, field_292, field_293))

law Bq.WearOK:
  (@+m_0: Bq.Maybe(Nat) -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> Data)))))

def Bq.WearOK(m_0, lv_1, str_2, agi_3, vit_4):
  match m_0:
    case Done{field_294}:
      {Bq.can_wear(field_294, lv_1, str_2, agi_3, vit_4) == True{} : Bool}
    case Fail{field_295}:
      Unit

law Bq.WellEquipped:
  (@+h_0: Bq.Hero -> Data)

def Bq.WellEquipped(h_0):
  match h_0:
    case Bq.Hero.Hero{field_296, field_297, field_298, field_299, field_300, field_301, field_302, field_303, field_304, field_305, field_306}:
      Bq.Pair.Pair(Bq.WearOK(field_297, field_302, field_303, field_304, field_305), (__11 => Bq.Pair.Pair(Bq.WearOK(field_298, field_302, field_303, field_304, field_305), (__12 => Bq.Pair.Pair(Bq.WearOK(field_299, field_302, field_303, field_304, field_305), (__13 => Bq.WearOK(field_300, field_302, field_303, field_304, field_305)))))))

law Bq.le_succ_r:
  (@+a_0: Nat -> (@+b_1: Nat -> (@+e_2: {Bq.Nat.le(a_0, b_1) == True{} : Bool} -> {Bq.Nat.le(a_0, Succ{b_1}) == True{} : Bool})))

def Bq.le_succ_r(a_0, b_1, e_2):
  match a_0:
    case Zero{}:
      {==}
    case Succ{field_307}:
      match b_1:
        case Zero{}:
          (apply_190 = {(ap_0 => \{}) : (@-ap_0: Nat -> (@+___1: Empty -> {Bq.Nat.le(ap_0, 0n) == True{} : Bool}))}; apply_190(field_307, Bq.Bool.false_ne_true(e_2)))
        case Succ{field_308}:
          Bq.le_succ_r(field_307, field_308, e_2)

law Bq.can_wear_mono_str:
  (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+e_5: {Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4) == True{} : Bool} -> {Bq.can_wear(k_0, lv_1, Succ{str_2}, agi_3, vit_4) == True{} : Bool}))))))

def Bq.can_wear_mono_str(k_0, lv_1, str_2, agi_3, vit_4, e_5):
  (+eL_6 = Bq.Bool.and_l(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), e_5); (+eR_7 = Bq.Bool.and_r(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), e_5); (+eS_8 = Bq.Bool.and_l(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4)), eR_7); (+e2_9 = Bq.Bool.and_r(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4)), eR_7); Bq.and_intro(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), Succ{str_2}), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), eL_6, Bq.and_intro(Bq.Nat.le(Bq.istreq(k_0), Succ{str_2}), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4)), Bq.le_succ_r(Bq.istreq(k_0), str_2, eS_8), e2_9))))))

law Bq.wear_ok_mono_str:
  (@+m_0: Bq.Maybe(Nat) -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+wo_5: Bq.WearOK(m_0, lv_1, str_2, agi_3, vit_4) -> Bq.WearOK(m_0, lv_1, Succ{str_2}, agi_3, vit_4)))))))

def Bq.wear_ok_mono_str(m_0, lv_1, str_2, agi_3, vit_4, wo_5):
  match m_0:
    case Done{field_309}:
      Bq.can_wear_mono_str(field_309, lv_1, str_2, agi_3, vit_4, wo_5)
    case Fail{field_310}:
      Unit{}

law Bq.can_wear_mono_agi:
  (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+e_5: {Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4) == True{} : Bool} -> {Bq.can_wear(k_0, lv_1, str_2, Succ{agi_3}, vit_4) == True{} : Bool}))))))

def Bq.can_wear_mono_agi(k_0, lv_1, str_2, agi_3, vit_4, e_5):
  (+eL_6 = Bq.Bool.and_l(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), e_5); (+eR_7 = Bq.Bool.and_r(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), e_5); (+eS_8 = Bq.Bool.and_l(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4)), eR_7); (+e2_9 = Bq.Bool.and_r(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4)), eR_7); (+eA_10 = Bq.Bool.and_l(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4), e2_9); (+eV_11 = Bq.Bool.and_r(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4), e2_9); Bq.and_intro(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), Succ{agi_3}), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), eL_6, Bq.and_intro(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), Succ{agi_3}), Bq.Nat.le(Bq.ivitreq(k_0), vit_4)), eS_8, Bq.and_intro(Bq.Nat.le(Bq.iagireq(k_0), Succ{agi_3}), Bq.Nat.le(Bq.ivitreq(k_0), vit_4), Bq.le_succ_r(Bq.iagireq(k_0), agi_3, eA_10), eV_11)))))))))

law Bq.wear_ok_mono_agi:
  (@+m_0: Bq.Maybe(Nat) -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+wo_5: Bq.WearOK(m_0, lv_1, str_2, agi_3, vit_4) -> Bq.WearOK(m_0, lv_1, str_2, Succ{agi_3}, vit_4)))))))

def Bq.wear_ok_mono_agi(m_0, lv_1, str_2, agi_3, vit_4, wo_5):
  match m_0:
    case Done{field_311}:
      Bq.can_wear_mono_agi(field_311, lv_1, str_2, agi_3, vit_4, wo_5)
    case Fail{field_312}:
      Unit{}

law Bq.can_wear_mono_vit:
  (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+e_5: {Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4) == True{} : Bool} -> {Bq.can_wear(k_0, lv_1, str_2, agi_3, Succ{vit_4}) == True{} : Bool}))))))

def Bq.can_wear_mono_vit(k_0, lv_1, str_2, agi_3, vit_4, e_5):
  (+eL_6 = Bq.Bool.and_l(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), e_5); (+eR_7 = Bq.Bool.and_r(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), e_5); (+eS_8 = Bq.Bool.and_l(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4)), eR_7); (+e2_9 = Bq.Bool.and_r(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4)), eR_7); (+eA_10 = Bq.Bool.and_l(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4), e2_9); (+eV_11 = Bq.Bool.and_r(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4), e2_9); Bq.and_intro(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), Succ{vit_4}))), eL_6, Bq.and_intro(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), Succ{vit_4})), eS_8, Bq.and_intro(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), Succ{vit_4}), eA_10, Bq.le_succ_r(Bq.ivitreq(k_0), vit_4, eV_11))))))))))

law Bq.wear_ok_mono_vit:
  (@+m_0: Bq.Maybe(Nat) -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+wo_5: Bq.WearOK(m_0, lv_1, str_2, agi_3, vit_4) -> Bq.WearOK(m_0, lv_1, str_2, agi_3, Succ{vit_4})))))))

def Bq.wear_ok_mono_vit(m_0, lv_1, str_2, agi_3, vit_4, wo_5):
  match m_0:
    case Done{field_313}:
      Bq.can_wear_mono_vit(field_313, lv_1, str_2, agi_3, vit_4, wo_5)
    case Fail{field_314}:
      Unit{}

law Bq.can_wear_mono_lv:
  (@+k_0: Nat -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+e_5: {Bq.can_wear(k_0, lv_1, str_2, agi_3, vit_4) == True{} : Bool} -> {Bq.can_wear(k_0, Succ{lv_1}, str_2, agi_3, vit_4) == True{} : Bool}))))))

def Bq.can_wear_mono_lv(k_0, lv_1, str_2, agi_3, vit_4, e_5):
  (+eL_6 = Bq.Bool.and_l(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), e_5); (+eR_7 = Bq.Bool.and_r(Bq.Nat.le(Bq.ilvreq(k_0), lv_1), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), e_5); Bq.and_intro(Bq.Nat.le(Bq.ilvreq(k_0), Succ{lv_1}), Bq.Bool.and(Bq.Nat.le(Bq.istreq(k_0), str_2), Bq.Bool.and(Bq.Nat.le(Bq.iagireq(k_0), agi_3), Bq.Nat.le(Bq.ivitreq(k_0), vit_4))), Bq.le_succ_r(Bq.ilvreq(k_0), lv_1, eL_6), eR_7)))

law Bq.wear_ok_mono_lv:
  (@+m_0: Bq.Maybe(Nat) -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+wo_5: Bq.WearOK(m_0, lv_1, str_2, agi_3, vit_4) -> Bq.WearOK(m_0, Succ{lv_1}, str_2, agi_3, vit_4)))))))

def Bq.wear_ok_mono_lv(m_0, lv_1, str_2, agi_3, vit_4, wo_5):
  match m_0:
    case Done{field_315}:
      Bq.can_wear_mono_lv(field_315, lv_1, str_2, agi_3, vit_4, wo_5)
    case Fail{field_316}:
      Unit{}

law Bq.ops_respect_requirements:
  (@+op_0: Bq.HOp -> (@+h_1: Bq.Hero -> (@+__2: Bq.WellEquipped(h_1) -> Bq.WellEquipped(Bq.hero_step(op_0, h_1)))))

def Bq.ops_respect_requirements(op_0, h_1, __2):
  match h_1:
    case Bq.Hero.Hero{field_317, field_318, field_319, field_320, field_321, field_322, field_323, field_324, field_325, field_326, field_327}:
      (apply_191 = {\{Bq.HOp.Equip: (k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (apply_192 = {(k_0 => (wea_1 => (lv_2 => (str_3 => (agi_4 => (vit_5 => (arm_6 => (hel_7 => (chm_8 => (inv_9 => (gold_10 => (pts_11 => \{Bq.ISlot.SlotNone: (ei_12 => \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}); \{Bq.ISlot.SlotW: (ei_12 => (apply_193 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (k_8 => (inv_9 => (gold_10 => (pts_11 => (ei_12 => \{False: \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}; \{True: (apply_194 = {(lv_0 => (str_1 => (agi_2 => (vit_3 => (arm_4 => (hel_5 => (chm_6 => (k_7 => (inv_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}); \{Fail: (error_12 => (apply_195 = {(k_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (inv_8 => (error_9 => (gold_10 => (pts_11 => (ei_12 => \{False: (cw_13 => \{Tuple: (ww_14 => \{Tuple: (wa_15 => \{Tuple: (wh_16 => (wc_17 => Tuple{ww_14, Tuple{wa_15, Tuple{wh_16, wc_17}}})); \{}}); \{}}); \{}}); \{True: (cw_13 => \{Tuple: (ww_14 => \{Tuple: (wa_15 => \{Tuple: (wh_16 => (wc_17 => (%Equal.sym(Bq.ISlot, (apply_196 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_196(Bq.item_info(k_0))), Bq.ISlot.SlotW{}, ei_12) : Bq.WellEquipped(({(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))})(inv_8, k_0, arm_5, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11, Fail{error_9}, _)); Tuple{cw_13, Tuple{wa_15, Tuple{wh_16, wc_17}}}))); \{}}); \{}}); \{}}); \{}}}))))))))))))) : (@-k_0: Nat -> (@-lv_1: Nat -> (@-str_2: Nat -> (@-agi_3: Nat -> (@-vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@-inv_8: List<&2, Nat> -> (@-error_9: Unit -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_197 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_197(Bq.item_info(k_0))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+___13: Bool -> (@+_e_14: {Bq.Bool.and(Bq.Nat.le((apply_198 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_198(Bq.item_info(k_0))), lv_1), Bq.Bool.and(Bq.Nat.le((apply_199 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_199(Bq.item_info(k_0))), str_2), Bq.Bool.and(Bq.Nat.le((apply_200 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_200(Bq.item_info(k_0))), agi_3), Bq.Nat.le((apply_201 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_201(Bq.item_info(k_0))), vit_4)))) == ___13 : Bool} -> (@+__15: Sigma<&2, &2, Unit, (__15 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__16 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__17 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(___13, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_8, Fail{error_9}, arm_5, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11}))))))))))))))))))}; apply_195(k_7, lv_0, str_1, agi_2, vit_3, arm_4, hel_5, chm_6, inv_8, error_12, gold_9, pts_10, ei_11, Bq.can_wear(k_7, lv_0, str_1, agi_2, vit_3), {==}))); \{}}})))))))))))) : (@+lv_0: Nat -> (@+str_1: Nat -> (@+agi_2: Nat -> (@+vit_3: Nat -> (@-arm_4: Result<&2, &2, Unit, Nat> -> (@-hel_5: Result<&2, &2, Unit, Nat> -> (@-chm_6: Result<&2, &2, Unit, Nat> -> (@+k_7: Nat -> (@-inv_8: List<&2, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_202 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_202(Bq.item_info(k_7))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> (@+__13: Sigma<&2, &2, Bq.WearOK(___12, lv_0, str_1, agi_2, vit_3), (__13 => Sigma<&2, &2, Bq.WearOK(arm_4, lv_0, str_1, agi_2, vit_3), (__14 => Sigma<&2, &2, Bq.WearOK(hel_5, lv_0, str_1, agi_2, vit_3), (__15 => Bq.WearOK(chm_6, lv_0, str_1, agi_2, vit_3))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), lv_0), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), str_1), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), agi_2), Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), vit_3))))), Bq.HOp.Equip{k_7}, Bq.Hero.Hero{inv_8, ___12, arm_4, hel_5, chm_6, gold_9, lv_0, str_1, agi_2, vit_3, pts_10}))))))))))))))))}; apply_194(lv_1, str_2, agi_3, vit_4, arm_5, hel_6, chm_7, k_8, inv_9, gold_10, pts_11, ei_12, wea_0)); \{}}}))))))))))))) : (@+wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@+k_8: Nat -> (@-inv_9: List<&2, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_203 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_203(Bq.item_info(k_8))) == Bq.ISlot.SlotW{} : Bq.ISlot} -> (@+___13: Bool -> (@+__14: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__15 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__16 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(wea_0), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), lv_1), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), str_2), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), agi_3), Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), vit_4)))))), Bq.HOp.Equip{k_8}, Bq.Hero.Hero{inv_9, wea_0, arm_5, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11})))))))))))))))))}; apply_193(wea_1, lv_2, str_3, agi_4, vit_5, arm_6, hel_7, chm_8, k_0, inv_9, gold_10, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_9)))); \{Bq.ISlot.SlotA: (ei_12 => (apply_204 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (k_8 => (inv_9 => (gold_10 => (pts_11 => (ei_12 => \{False: \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}; \{True: (apply_205 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (hel_5 => (chm_6 => (k_7 => (inv_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}); \{Fail: (error_12 => (apply_206 = {(k_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (wea_5 => (hel_6 => (chm_7 => (inv_8 => (error_9 => (gold_10 => (pts_11 => (ei_12 => \{False: (cw_13 => \{Tuple: (ww_14 => \{Tuple: (wa_15 => \{Tuple: (wh_16 => (wc_17 => Tuple{ww_14, Tuple{wa_15, Tuple{wh_16, wc_17}}})); \{}}); \{}}); \{}}); \{True: (cw_13 => \{Tuple: (ww_14 => \{Tuple: (wa_15 => \{Tuple: (wh_16 => (wc_17 => (%Equal.sym(Bq.ISlot, (apply_207 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_207(Bq.item_info(k_0))), Bq.ISlot.SlotA{}, ei_12) : Bq.WellEquipped(({(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))})(inv_8, k_0, Fail{error_9}, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11, wea_5, _)); Tuple{ww_14, Tuple{cw_13, Tuple{wh_16, wc_17}}}))); \{}}); \{}}); \{}}); \{}}}))))))))))))) : (@-k_0: Nat -> (@-lv_1: Nat -> (@-str_2: Nat -> (@-agi_3: Nat -> (@-vit_4: Nat -> (@-wea_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@-inv_8: List<&2, Nat> -> (@-error_9: Unit -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_208 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_208(Bq.item_info(k_0))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+___13: Bool -> (@+_e_14: {Bq.Bool.and(Bq.Nat.le((apply_209 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_209(Bq.item_info(k_0))), lv_1), Bq.Bool.and(Bq.Nat.le((apply_210 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_210(Bq.item_info(k_0))), str_2), Bq.Bool.and(Bq.Nat.le((apply_211 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_211(Bq.item_info(k_0))), agi_3), Bq.Nat.le((apply_212 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_212(Bq.item_info(k_0))), vit_4)))) == ___13 : Bool} -> (@+__15: Sigma<&2, &2, Bq.WearOK(wea_5, lv_1, str_2, agi_3, vit_4), (__15 => Sigma<&2, &2, Unit, (__16 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__17 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(___13, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_8, wea_5, Fail{error_9}, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11}))))))))))))))))))}; apply_206(k_7, lv_1, str_2, agi_3, vit_4, wea_0, hel_5, chm_6, inv_8, error_12, gold_9, pts_10, ei_11, Bq.can_wear(k_7, lv_1, str_2, agi_3, vit_4), {==}))); \{}}})))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-hel_5: Result<&2, &2, Unit, Nat> -> (@-chm_6: Result<&2, &2, Unit, Nat> -> (@+k_7: Nat -> (@-inv_8: List<&2, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_213 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_213(Bq.item_info(k_7))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> (@+__13: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__13 => Sigma<&2, &2, Bq.WearOK(___12, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(hel_5, lv_1, str_2, agi_3, vit_4), (__15 => Bq.WearOK(chm_6, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), lv_1), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), str_2), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), agi_3), Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), vit_4))))), Bq.HOp.Equip{k_7}, Bq.Hero.Hero{inv_8, wea_0, ___12, hel_5, chm_6, gold_9, lv_1, str_2, agi_3, vit_4, pts_10}))))))))))))))))}; apply_205(wea_0, lv_1, str_2, agi_3, vit_4, hel_6, chm_7, k_8, inv_9, gold_10, pts_11, ei_12, arm_5)); \{}}}))))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+arm_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@+k_8: Nat -> (@-inv_9: List<&2, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_214 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_214(Bq.item_info(k_8))) == Bq.ISlot.SlotA{} : Bq.ISlot} -> (@+___13: Bool -> (@+__14: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__15 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__16 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(arm_5), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), lv_1), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), str_2), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), agi_3), Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), vit_4)))))), Bq.HOp.Equip{k_8}, Bq.Hero.Hero{inv_9, wea_0, arm_5, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11})))))))))))))))))}; apply_204(wea_1, lv_2, str_3, agi_4, vit_5, arm_6, hel_7, chm_8, k_0, inv_9, gold_10, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_9)))); \{Bq.ISlot.SlotH: (ei_12 => (apply_215 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (k_8 => (inv_9 => (gold_10 => (pts_11 => (ei_12 => \{False: \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}; \{True: (apply_216 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (chm_6 => (k_7 => (inv_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}); \{Fail: (error_12 => (apply_217 = {(k_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (wea_5 => (arm_6 => (chm_7 => (inv_8 => (error_9 => (gold_10 => (pts_11 => (ei_12 => \{False: (cw_13 => \{Tuple: (ww_14 => \{Tuple: (wa_15 => \{Tuple: (wh_16 => (wc_17 => Tuple{ww_14, Tuple{wa_15, Tuple{wh_16, wc_17}}})); \{}}); \{}}); \{}}); \{True: (cw_13 => \{Tuple: (ww_14 => \{Tuple: (wa_15 => \{Tuple: (wh_16 => (wc_17 => (%Equal.sym(Bq.ISlot, (apply_218 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_218(Bq.item_info(k_0))), Bq.ISlot.SlotH{}, ei_12) : Bq.WellEquipped(({(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))})(inv_8, k_0, arm_6, Fail{error_9}, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11, wea_5, _)); Tuple{ww_14, Tuple{wa_15, Tuple{cw_13, wc_17}}}))); \{}}); \{}}); \{}}); \{}}}))))))))))))) : (@-k_0: Nat -> (@-lv_1: Nat -> (@-str_2: Nat -> (@-agi_3: Nat -> (@-vit_4: Nat -> (@-wea_5: Result<&2, &2, Unit, Nat> -> (@-arm_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@-inv_8: List<&2, Nat> -> (@-error_9: Unit -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_219 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_219(Bq.item_info(k_0))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+___13: Bool -> (@+_e_14: {Bq.Bool.and(Bq.Nat.le((apply_220 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_220(Bq.item_info(k_0))), lv_1), Bq.Bool.and(Bq.Nat.le((apply_221 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_221(Bq.item_info(k_0))), str_2), Bq.Bool.and(Bq.Nat.le((apply_222 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_222(Bq.item_info(k_0))), agi_3), Bq.Nat.le((apply_223 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_223(Bq.item_info(k_0))), vit_4)))) == ___13 : Bool} -> (@+__15: Sigma<&2, &2, Bq.WearOK(wea_5, lv_1, str_2, agi_3, vit_4), (__15 => Sigma<&2, &2, Bq.WearOK(arm_6, lv_1, str_2, agi_3, vit_4), (__16 => Sigma<&2, &2, Unit, (__17 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(___13, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_8, wea_5, arm_6, Fail{error_9}, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11}))))))))))))))))))}; apply_217(k_7, lv_1, str_2, agi_3, vit_4, wea_0, arm_5, chm_6, inv_8, error_12, gold_9, pts_10, ei_11, Bq.can_wear(k_7, lv_1, str_2, agi_3, vit_4), {==}))); \{}}})))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@-chm_6: Result<&2, &2, Unit, Nat> -> (@+k_7: Nat -> (@-inv_8: List<&2, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_224 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_224(Bq.item_info(k_7))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> (@+__13: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__13 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(___12, lv_1, str_2, agi_3, vit_4), (__15 => Bq.WearOK(chm_6, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), lv_1), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), str_2), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), agi_3), Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), vit_4))))), Bq.HOp.Equip{k_7}, Bq.Hero.Hero{inv_8, wea_0, arm_5, ___12, chm_6, gold_9, lv_1, str_2, agi_3, vit_4, pts_10}))))))))))))))))}; apply_216(wea_0, lv_1, str_2, agi_3, vit_4, arm_5, chm_7, k_8, inv_9, gold_10, pts_11, ei_12, hel_6)); \{}}}))))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@+hel_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@+k_8: Nat -> (@-inv_9: List<&2, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_225 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_225(Bq.item_info(k_8))) == Bq.ISlot.SlotH{} : Bq.ISlot} -> (@+___13: Bool -> (@+__14: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__15 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__16 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(hel_6), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), lv_1), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), str_2), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), agi_3), Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), vit_4)))))), Bq.HOp.Equip{k_8}, Bq.Hero.Hero{inv_9, wea_0, arm_5, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11})))))))))))))))))}; apply_215(wea_1, lv_2, str_3, agi_4, vit_5, arm_6, hel_7, chm_8, k_0, inv_9, gold_10, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_9)))); \{Bq.ISlot.SlotC: (ei_12 => (apply_226 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (k_8 => (inv_9 => (gold_10 => (pts_11 => (ei_12 => \{False: \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}; \{True: (apply_227 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (k_7 => (inv_8 => (gold_9 => (pts_10 => (ei_11 => \{Done: (value_12 => \{Tuple: (ww_13 => \{Tuple: (wa_14 => \{Tuple: (wh_15 => (wc_16 => Tuple{ww_13, Tuple{wa_14, Tuple{wh_15, wc_16}}})); \{}}); \{}}); \{}}); \{Fail: (error_12 => (apply_228 = {(k_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (wea_5 => (arm_6 => (hel_7 => (inv_8 => (error_9 => (gold_10 => (pts_11 => (ei_12 => \{False: (cw_13 => \{Tuple: (ww_14 => \{Tuple: (wa_15 => \{Tuple: (wh_16 => (wc_17 => Tuple{ww_14, Tuple{wa_15, Tuple{wh_16, wc_17}}})); \{}}); \{}}); \{}}); \{True: (cw_13 => \{Tuple: (ww_14 => \{Tuple: (wa_15 => \{Tuple: (wh_16 => (wc_17 => (%Equal.sym(Bq.ISlot, (apply_229 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_229(Bq.item_info(k_0))), Bq.ISlot.SlotC{}, ei_12) : Bq.WellEquipped(({(inv_0 => (k_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (wea_11 => \{Bq.ISlot.SlotW: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), Bq.Maybe.some(Nat, k_1), arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotA: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, Bq.Maybe.some(Nat, k_1), hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotH: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, Bq.Maybe.some(Nat, k_1), chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotC: Bq.Hero.Hero{Bq.Bag.sub(inv_0, Bq.one(k_1)), wea_11, arm_2, hel_3, Bq.Maybe.some(Nat, k_1), gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{Bq.ISlot.SlotNone: Bq.Hero.Hero{inv_0, wea_11, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, pts_10}; \{}}}}}})))))))))))) : (@+inv_0: Bq.Bag -> (@+k_1: Nat -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+pts_10: Nat -> (@+wea_11: Bq.Maybe(Nat) -> (@+___12: Bq.ISlot -> Bq.Hero)))))))))))))})(inv_8, k_0, arm_6, hel_7, Fail{error_9}, gold_10, lv_1, str_2, agi_3, vit_4, pts_11, wea_5, _)); Tuple{ww_14, Tuple{wa_15, Tuple{wh_16, cw_13}}}))); \{}}); \{}}); \{}}); \{}}}))))))))))))) : (@-k_0: Nat -> (@-lv_1: Nat -> (@-str_2: Nat -> (@-agi_3: Nat -> (@-vit_4: Nat -> (@-wea_5: Result<&2, &2, Unit, Nat> -> (@-arm_6: Result<&2, &2, Unit, Nat> -> (@-hel_7: Result<&2, &2, Unit, Nat> -> (@-inv_8: List<&2, Nat> -> (@-error_9: Unit -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_230 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_230(Bq.item_info(k_0))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+___13: Bool -> (@+_e_14: {Bq.Bool.and(Bq.Nat.le((apply_231 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_231(Bq.item_info(k_0))), lv_1), Bq.Bool.and(Bq.Nat.le((apply_232 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_232(Bq.item_info(k_0))), str_2), Bq.Bool.and(Bq.Nat.le((apply_233 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_233(Bq.item_info(k_0))), agi_3), Bq.Nat.le((apply_234 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)}; apply_234(Bq.item_info(k_0))), vit_4)))) == ___13 : Bool} -> (@+__15: Sigma<&2, &2, Bq.WearOK(wea_5, lv_1, str_2, agi_3, vit_4), (__15 => Sigma<&2, &2, Bq.WearOK(arm_6, lv_1, str_2, agi_3, vit_4), (__16 => Sigma<&2, &2, Bq.WearOK(hel_7, lv_1, str_2, agi_3, vit_4), (__17 => Unit)>)>)> -> Bq.WellEquipped(Bq.hero_step_go(___13, Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_8, wea_5, arm_6, hel_7, Fail{error_9}, gold_10, lv_1, str_2, agi_3, vit_4, pts_11}))))))))))))))))))}; apply_228(k_7, lv_1, str_2, agi_3, vit_4, wea_0, arm_5, hel_6, inv_8, error_12, gold_9, pts_10, ei_11, Bq.can_wear(k_7, lv_1, str_2, agi_3, vit_4), {==}))); \{}}})))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@+k_7: Nat -> (@-inv_8: List<&2, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+ei_11: {(apply_235 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_235(Bq.item_info(k_7))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+___12: Result<&2, &2, Unit, Nat> -> (@+__13: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__13 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__15 => Bq.WearOK(___12, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(Bq.slot_empty(___12), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), lv_1), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), str_2), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), agi_3), Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_7)), vit_4))))), Bq.HOp.Equip{k_7}, Bq.Hero.Hero{inv_8, wea_0, arm_5, hel_6, ___12, gold_9, lv_1, str_2, agi_3, vit_4, pts_10}))))))))))))))))}; apply_227(wea_0, lv_1, str_2, agi_3, vit_4, arm_5, hel_6, k_8, inv_9, gold_10, pts_11, ei_12, chm_7)); \{}}}))))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@+chm_7: Result<&2, &2, Unit, Nat> -> (@+k_8: Nat -> (@-inv_9: List<&2, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+ei_12: {(apply_236 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_236(Bq.item_info(k_8))) == Bq.ISlot.SlotC{} : Bq.ISlot} -> (@+___13: Bool -> (@+__14: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__15 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__16 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(___13, Bq.Bool.and(Bq.slot_empty(chm_7), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => lvreq_1)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), lv_1), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => streq_2)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), str_2), Bq.Bool.and(Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => agireq_3)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), agi_3), Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => vitreq_4)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), vit_4)))))), Bq.HOp.Equip{k_8}, Bq.Hero.Hero{inv_9, wea_0, arm_5, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11})))))))))))))))))}; apply_226(wea_1, lv_2, str_3, agi_4, vit_5, arm_6, hel_7, chm_8, k_0, inv_9, gold_10, pts_11, ei_12, Bq.Bag.le(Bq.one(k_0), inv_9)))); \{}}}}}})))))))))))) : (@+k_0: Nat -> (@+wea_1: Result<&2, &2, Unit, Nat> -> (@+lv_2: Nat -> (@+str_3: Nat -> (@+agi_4: Nat -> (@+vit_5: Nat -> (@+arm_6: Result<&2, &2, Unit, Nat> -> (@+hel_7: Result<&2, &2, Unit, Nat> -> (@+chm_8: Result<&2, &2, Unit, Nat> -> (@+inv_9: List<&2, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+___12: Bq.ISlot -> (@+_e_13: {(apply_237 = {\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => slot_0)))))))); \{}} : (@+___0: Bq.Info -> Bq.ISlot)}; apply_237(Bq.item_info(k_0))) == ___12 : Bq.ISlot} -> (@+__14: Sigma<&2, &2, Bq.WearOK(wea_1, lv_2, str_3, agi_4, vit_5), (__14 => Sigma<&2, &2, Bq.WearOK(arm_6, lv_2, str_3, agi_4, vit_5), (__15 => Sigma<&2, &2, Bq.WearOK(hel_7, lv_2, str_3, agi_4, vit_5), (__16 => Bq.WearOK(chm_8, lv_2, str_3, agi_4, vit_5))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(({(k_0 => (h_1 => \{Bq.ISlot.SlotNone: False{}; \{Bq.ISlot.SlotW: (apply_238 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(wea_2), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_238(k_0, h_1)); \{Bq.ISlot.SlotA: (apply_239 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(arm_3), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_239(k_0, h_1)); \{Bq.ISlot.SlotH: (apply_240 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(hel_4), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_240(k_0, h_1)); \{Bq.ISlot.SlotC: (apply_241 = {(k_0 => \{Bq.Hero.Hero: (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => Bq.Bool.and(Bq.Bag.le(Bq.one(k_0), inv_1), Bq.Bool.and(Bq.slot_empty(chm_5), Bq.can_wear(k_0, lv_7, str_8, agi_9, vit_10)))))))))))))); \{}}) : (@+k_0: Nat -> (@+___1: Bq.Hero -> Bool))}; apply_241(k_0, h_1)); \{}}}}}})) : (@+k_0: Nat -> (@+h_1: Bq.Hero -> (@+___2: Bq.ISlot -> Bool)))})(k_0, Bq.Hero.Hero{inv_9, wea_1, arm_6, hel_7, chm_8, gold_10, lv_2, str_3, agi_4, vit_5, pts_11}, ___12), Bq.HOp.Equip{k_0}, Bq.Hero.Hero{inv_9, wea_1, arm_6, hel_7, chm_8, gold_10, lv_2, str_3, agi_4, vit_5, pts_11})))))))))))))))))}; apply_192(k_0, wea_2, lv_7, str_8, agi_9, vit_10, arm_3, hel_4, chm_5, inv_1, gold_6, pts_11, Bq.islot(k_0), {==})))))))))))))); \{Bq.HOp.Unequip: (s_0 => (apply_242 = {\{Bq.ISlot.SlotNone: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}}))))))))))); \{Bq.ISlot.SlotW: (inv_0 => \{Fail: (u_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}})))))))))); \{Done: (k0_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{Unit{}, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}})))))))))); \{}}}); \{Bq.ISlot.SlotA: (inv_0 => (wea_1 => \{Fail: (u_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}}))))))))); \{Done: (k0_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{Unit{}, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}}))))))))); \{}}})); \{Bq.ISlot.SlotH: (inv_0 => (wea_1 => (arm_2 => \{Fail: (u_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}})))))))); \{Done: (k0_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{Unit{}, wc_14}}})); \{}}); \{}}); \{}})))))))); \{}}}))); \{Bq.ISlot.SlotC: (inv_0 => (wea_1 => (arm_2 => (hel_3 => \{Fail: (u_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}}))))))); \{Done: (k0_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, Unit{}}}})); \{}}); \{}}); \{}}))))))); \{}}})))); \{}}}}}} : (@+___0: Bq.ISlot -> (@+__1: List<&2, Nat> -> (@+__2: Result<&2, &2, Unit, Nat> -> (@+__3: Result<&2, &2, Unit, Nat> -> (@+__4: Result<&2, &2, Unit, Nat> -> (@+__5: Result<&2, &2, Unit, Nat> -> (@+__6: Nat -> (@+__7: Nat -> (@+__8: Nat -> (@+__9: Nat -> (@+__10: Nat -> (@+__11: Nat -> (@+__12: Sigma<&2, &2, Bq.WearOK(__2, __7, __8, __9, __10), (__12 => Sigma<&2, &2, Bq.WearOK(__3, __7, __8, __9, __10), (__13 => Sigma<&2, &2, Bq.WearOK(__4, __7, __8, __9, __10), (__14 => Bq.WearOK(__5, __7, __8, __9, __10))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.not(Bq.slot_empty(Bq.slot_of(Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11}, ___0))), Bq.HOp.Unequip{___0}, Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11})))))))))))))))}; apply_242(s_0))); \{Bq.HOp.Buy: (k_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => (pts_11 => (apply_243 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (k_8 => (gold_9 => (inv_10 => (pts_11 => \{False: \{Tuple: (ww_12 => \{Tuple: (wa_13 => \{Tuple: (wh_14 => (wc_15 => Tuple{ww_12, Tuple{wa_13, Tuple{wh_14, wc_15}}})); \{}}); \{}}); \{}}; \{True: (apply_244 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (k_8 => (inv_9 => (gold_10 => (pts_11 => \{False: \{Tuple: (ww_12 => \{Tuple: (wa_13 => \{Tuple: (wh_14 => (wc_15 => Tuple{ww_12, Tuple{wa_13, Tuple{wh_14, wc_15}}})); \{}}); \{}}); \{}}; \{True: \{Tuple: (ww_12 => \{Tuple: (wa_13 => \{Tuple: (wh_14 => (wc_15 => Tuple{ww_12, Tuple{wa_13, Tuple{wh_14, wc_15}}})); \{}}); \{}}); \{}}; \{}}})))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@-lv_1: Nat -> (@-str_2: Nat -> (@-agi_3: Nat -> (@-vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@-k_8: Nat -> (@-inv_9: List<&2, Nat> -> (@-gold_10: Nat -> (@-pts_11: Nat -> (@+___12: Bool -> (@+__13: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__13 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__15 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(___12, Bq.HOp.Buy{k_8}, Bq.Hero.Hero{inv_9, wea_0, arm_5, hel_6, chm_7, gold_10, lv_1, str_2, agi_3, vit_4, pts_11}))))))))))))))))}; apply_244(wea_0, lv_1, str_2, agi_3, vit_4, arm_5, hel_6, chm_7, k_8, inv_10, gold_9, pts_11, Bq.Nat.le(Bq.iprice(k_8), gold_9))); \{}}})))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@-lv_1: Nat -> (@-str_2: Nat -> (@-agi_3: Nat -> (@-vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@+k_8: Nat -> (@+gold_9: Nat -> (@-inv_10: List<&2, Nat> -> (@-pts_11: Nat -> (@+___12: Bool -> (@+__13: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__13 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__14 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__15 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.Bool.and(___12, Bq.Nat.le(({\{Bq.Info.Info: (slot_0 => (lvreq_1 => (streq_2 => (agireq_3 => (vitreq_4 => (atk_5 => (df_6 => (price_7 => price_7)))))))); \{}} : (@+___0: Bq.Info -> Nat)})(Bq.item_info(k_8)), gold_9)), Bq.HOp.Buy{k_8}, Bq.Hero.Hero{inv_10, wea_0, arm_5, hel_6, chm_7, gold_9, lv_1, str_2, agi_3, vit_4, pts_11}))))))))))))))))}; apply_243(wea_2, lv_7, str_8, agi_9, vit_10, arm_3, hel_4, chm_5, k_0, gold_6, inv_1, pts_11, Bq.Nat.lt(0n, Bq.iprice(k_0)))))))))))))))); \{Bq.HOp.Quaff: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => (apply_245 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (inv_8 => (gold_9 => (pts_10 => \{False: \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}}; \{True: \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}}; \{}}}))))))))))) : (@-wea_0: Result<&2, &2, Unit, Nat> -> (@-lv_1: Nat -> (@-str_2: Nat -> (@-agi_3: Nat -> (@-vit_4: Nat -> (@-arm_5: Result<&2, &2, Unit, Nat> -> (@-hel_6: Result<&2, &2, Unit, Nat> -> (@-chm_7: Result<&2, &2, Unit, Nat> -> (@-inv_8: List<&2, Nat> -> (@-gold_9: Nat -> (@-pts_10: Nat -> (@+___11: Bool -> (@+__12: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__12 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__13 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__14 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(___11, Bq.HOp.Quaff{}, Bq.Hero.Hero{inv_8, wea_0, arm_5, hel_6, chm_7, gold_9, lv_1, str_2, agi_3, vit_4, pts_10})))))))))))))))}; apply_245(wea_1, lv_6, str_7, agi_8, vit_9, arm_2, hel_3, chm_4, inv_0, gold_5, pts_10, Bq.Bag.le(Bq.one(Bq.POTION), inv_0)))))))))))))); \{Bq.HOp.Alloc: (s_0 => (inv_1 => (wea_2 => (arm_3 => (hel_4 => (chm_5 => (gold_6 => (lv_7 => (str_8 => (agi_9 => (vit_10 => \{Zero: \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{ww_11, Tuple{wa_12, Tuple{wh_13, wc_14}}})); \{}}); \{}}); \{}}; \{Succ: (field_246 => (apply_247 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (inv_8 => (gold_9 => \{Zero: (p_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{Bq.wear_ok_mono_str(wea_0, lv_1, str_2, agi_3, vit_4, ww_11), Tuple{Bq.wear_ok_mono_str(arm_5, lv_1, str_2, agi_3, vit_4, wa_12), Tuple{Bq.wear_ok_mono_str(hel_6, lv_1, str_2, agi_3, vit_4, wh_13), Bq.wear_ok_mono_str(chm_7, lv_1, str_2, agi_3, vit_4, wc_14)}}})); \{}}); \{}}); \{}}); \{Succ: (p_10 => (apply_248 = {(wea_0 => (lv_1 => (str_2 => (agi_3 => (vit_4 => (arm_5 => (hel_6 => (chm_7 => (inv_8 => (gold_9 => \{Zero: (p_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{Bq.wear_ok_mono_agi(wea_0, lv_1, str_2, agi_3, vit_4, ww_11), Tuple{Bq.wear_ok_mono_agi(arm_5, lv_1, str_2, agi_3, vit_4, wa_12), Tuple{Bq.wear_ok_mono_agi(hel_6, lv_1, str_2, agi_3, vit_4, wh_13), Bq.wear_ok_mono_agi(chm_7, lv_1, str_2, agi_3, vit_4, wc_14)}}})); \{}}); \{}}); \{}}); \{Succ: (p_10 => (p_11 => \{Tuple: (ww_12 => \{Tuple: (wa_13 => \{Tuple: (wh_14 => (wc_15 => Tuple{Bq.wear_ok_mono_vit(wea_0, lv_1, str_2, agi_3, vit_4, ww_12), Tuple{Bq.wear_ok_mono_vit(arm_5, lv_1, str_2, agi_3, vit_4, wa_13), Tuple{Bq.wear_ok_mono_vit(hel_6, lv_1, str_2, agi_3, vit_4, wh_14), Bq.wear_ok_mono_vit(chm_7, lv_1, str_2, agi_3, vit_4, wc_15)}}})); \{}}); \{}}); \{}})); \{}}})))))))))) : (@+wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+arm_5: Result<&2, &2, Unit, Nat> -> (@+hel_6: Result<&2, &2, Unit, Nat> -> (@+chm_7: Result<&2, &2, Unit, Nat> -> (@-inv_8: List<&2, Nat> -> (@-gold_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> (@+__12: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__12 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__13 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__14 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(({(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, Succ{agi_8}, vit_9, p_10}); \{Succ: (p_10 => (p_11 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, Succ{vit_9}, p_11})); \{}}})))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))})(inv_8, wea_0, arm_5, hel_6, chm_7, gold_9, lv_1, str_2, agi_3, vit_4, ___10, __11)))))))))))))))}; apply_248(wea_0, lv_1, str_2, agi_3, vit_4, arm_5, hel_6, chm_7, inv_8, gold_9, p_10))); \{}}})))))))))) : (@+wea_0: Result<&2, &2, Unit, Nat> -> (@+lv_1: Nat -> (@+str_2: Nat -> (@+agi_3: Nat -> (@+vit_4: Nat -> (@+arm_5: Result<&2, &2, Unit, Nat> -> (@+hel_6: Result<&2, &2, Unit, Nat> -> (@+chm_7: Result<&2, &2, Unit, Nat> -> (@-inv_8: List<&2, Nat> -> (@-gold_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> (@+__12: Sigma<&2, &2, Bq.WearOK(wea_0, lv_1, str_2, agi_3, vit_4), (__12 => Sigma<&2, &2, Bq.WearOK(arm_5, lv_1, str_2, agi_3, vit_4), (__13 => Sigma<&2, &2, Bq.WearOK(hel_6, lv_1, str_2, agi_3, vit_4), (__14 => Bq.WearOK(chm_7, lv_1, str_2, agi_3, vit_4))>)>)> -> Bq.WellEquipped(({(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, Succ{str_7}, agi_8, vit_9, p_10}); \{Succ: (p_10 => (apply_249 = {(inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => \{Zero: (p_10 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, Succ{agi_8}, vit_9, p_10}); \{Succ: (p_10 => (p_11 => Bq.Hero.Hero{inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, Succ{vit_9}, p_11})); \{}}})))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))}; apply_249(inv_0, wea_1, arm_2, hel_3, chm_4, gold_5, lv_6, str_7, agi_8, vit_9, p_10))); \{}}})))))))))) : (@+inv_0: Bq.Bag -> (@+wea_1: Bq.Maybe(Nat) -> (@+arm_2: Bq.Maybe(Nat) -> (@+hel_3: Bq.Maybe(Nat) -> (@+chm_4: Bq.Maybe(Nat) -> (@+gold_5: Nat -> (@+lv_6: Nat -> (@+str_7: Nat -> (@+agi_8: Nat -> (@+vit_9: Nat -> (@+___10: Nat -> (@+__11: Nat -> Bq.Hero))))))))))))})(inv_8, wea_0, arm_5, hel_6, chm_7, gold_9, lv_1, str_2, agi_3, vit_4, ___10, __11)))))))))))))))}; apply_247(wea_2, lv_7, str_8, agi_9, vit_10, arm_3, hel_4, chm_5, inv_1, gold_6, s_0, field_246))); \{}}}))))))))))); \{Bq.HOp.LevelUp: (inv_0 => (wea_1 => (arm_2 => (hel_3 => (chm_4 => (gold_5 => (lv_6 => (str_7 => (agi_8 => (vit_9 => (pts_10 => \{Tuple: (ww_11 => \{Tuple: (wa_12 => \{Tuple: (wh_13 => (wc_14 => Tuple{Bq.wear_ok_mono_lv(wea_1, lv_6, str_7, agi_8, vit_9, ww_11), Tuple{Bq.wear_ok_mono_lv(arm_2, lv_6, str_7, agi_8, vit_9, wa_12), Tuple{Bq.wear_ok_mono_lv(hel_3, lv_6, str_7, agi_8, vit_9, wh_13), Bq.wear_ok_mono_lv(chm_4, lv_6, str_7, agi_8, vit_9, wc_14)}}})); \{}}); \{}}); \{}}))))))))))); \{}}}}}}} : (@+___0: Bq.HOp -> (@+__1: List<&2, Nat> -> (@+__2: Result<&2, &2, Unit, Nat> -> (@+__3: Result<&2, &2, Unit, Nat> -> (@+__4: Result<&2, &2, Unit, Nat> -> (@+__5: Result<&2, &2, Unit, Nat> -> (@+__6: Nat -> (@+__7: Nat -> (@+__8: Nat -> (@+__9: Nat -> (@+__10: Nat -> (@+__11: Nat -> (@+__12: Sigma<&2, &2, Bq.WearOK(__2, __7, __8, __9, __10), (__12 => Sigma<&2, &2, Bq.WearOK(__3, __7, __8, __9, __10), (__13 => Sigma<&2, &2, Bq.WearOK(__4, __7, __8, __9, __10), (__14 => Bq.WearOK(__5, __7, __8, __9, __10))>)>)> -> Bq.WellEquipped(Bq.hero_step_go(Bq.hop_ok(___0, Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11}), ___0, Bq.Hero.Hero{__1, __2, __3, __4, __5, __6, __7, __8, __9, __10, __11})))))))))))))))}; apply_191(op_0, field_317, field_318, field_319, field_320, field_321, field_322, field_323, field_324, field_325, field_326, field_327, __2))

law Bq.nmin_le_r:
  (@+a_0: Nat -> (@+b_1: Nat -> {Bq.Nat.le(Bq.nmin(a_0, b_1), b_1) == True{} : Bool}))

def Bq.nmin_le_r(a_0, b_1):
  match a_0:
    case Zero{}:
      {==}
    case Succ{field_328}:
      match b_1:
        case Zero{}:
          {==}
        case Succ{field_329}:
          Bq.nmin_le_r(field_328, field_329)

law Bq.damage_capped:
  (@+watk_0: Nat -> (@+str_1: Nat -> (@+df_2: Nat -> (@+crit_3: Bool -> {Bq.Nat.le(Bq.damage(watk_0, str_1, df_2, crit_3), Bq.DMG_CAP) == True{} : Bool}))))

def Bq.damage_capped(watk_0, str_1, df_2, crit_3):
  Bq.nmin_le_r(Bq.nmax(Bq.Nat.sub(Bq.crit_dbl(crit_3, Bq.Nat.add(watk_0, Bq.Nat.dbl(str_1))), df_2), 1n), Bq.DMG_CAP)

law Bq.nmin_pos:
  (@+a_0: Nat -> (@+b_1: Nat -> (@+ea_2: {Bq.Nat.le(1n, a_0) == True{} : Bool} -> (@+eb_3: {Bq.Nat.le(1n, b_1) == True{} : Bool} -> {Bq.Nat.le(1n, Bq.nmin(a_0, b_1)) == True{} : Bool}))))

def Bq.nmin_pos(a_0, b_1, ea_2, eb_3):
  match a_0:
    case Zero{}:
      (apply_250 = {\{} : (@+___0: Empty -> {False{} == True{} : Bool})}; apply_250(Bq.Bool.false_ne_true(ea_2)))
    case Succ{field_330}:
      match b_1:
        case Zero{}:
          (apply_251 = {\{} : (@+___0: Empty -> {False{} == True{} : Bool})}; apply_251(Bq.Bool.false_ne_true(eb_3)))
        case Succ{field_331}:
          {==}

law Bq.nmax_ge_one:
  (@+x_0: Nat -> {Bq.Nat.le(1n, Bq.nmax(x_0, 1n)) == True{} : Bool})

def Bq.nmax_ge_one(x_0):
  match x_0:
    case Zero{}:
      {==}
    case Succ{field_332}:
      {==}

law Bq.damage_at_least_one:
  (@+watk_0: Nat -> (@+str_1: Nat -> (@+df_2: Nat -> (@+crit_3: Bool -> {Bq.Nat.le(1n, Bq.damage(watk_0, str_1, df_2, crit_3)) == True{} : Bool}))))

def Bq.damage_at_least_one(watk_0, str_1, df_2, crit_3):
  Bq.nmin_pos(Bq.nmax(Bq.Nat.sub(Bq.crit_dbl(crit_3, Bq.Nat.add(watk_0, Bq.Nat.dbl(str_1))), df_2), 1n), Bq.DMG_CAP, Bq.nmax_ge_one(Bq.Nat.sub(Bq.crit_dbl(crit_3, Bq.Nat.add(watk_0, Bq.Nat.dbl(str_1))), df_2)), {==})

law Bq.le_nmax:
  (@+a_0: Nat -> (@+b_1: Nat -> (@+c_2: Nat -> (@+ea_3: {Bq.Nat.le(a_0, c_2) == True{} : Bool} -> (@+eb_4: {Bq.Nat.le(b_1, c_2) == True{} : Bool} -> {Bq.Nat.le(Bq.nmax(a_0, b_1), c_2) == True{} : Bool})))))

def Bq.le_nmax(a_0, b_1, c_2, ea_3, eb_4):
  match a_0:
    case Zero{}:
      eb_4
    case Succ{field_333}:
      match b_1:
        case Zero{}:
          ea_3
        case Succ{field_334}:
          match c_2:
            case Zero{}:
              (apply_252 = {\{} : (@+___0: Empty -> {False{} == True{} : Bool})}; apply_252(Bq.Bool.false_ne_true(ea_3)))
            case Succ{field_335}:
              Bq.le_nmax(field_333, field_334, field_335, ea_3, eb_4)

law Bq.no_instakill:
  (@+matk_0: Nat -> (@+df_1: Nat -> (@+lv_2: Nat -> (@+vit_3: Nat -> {Bq.Nat.lt(Bq.mob_damage(matk_0, df_1, Bq.max_hp(lv_2, vit_3)), Bq.max_hp(lv_2, vit_3)) == True{} : Bool}))))

def Bq.no_instakill(matk_0, df_1, lv_2, vit_3):
  Bq.le_nmax(Bq.nmin(Bq.nmax(Bq.Nat.sub(matk_0, df_1), 1n), Bq.Nat.pred(Bq.max_hp(lv_2, vit_3))), 1n, Bq.Nat.pred(Bq.max_hp(lv_2, vit_3)), Bq.nmin_le_r(Bq.nmax(Bq.Nat.sub(matk_0, df_1), 1n), Bq.Nat.pred(Bq.max_hp(lv_2, vit_3))), {==})

law Bq.le_step_down:
  (@+a_0: Nat -> (@+b_1: Nat -> (@+e_2: {Bq.Nat.le(Succ{a_0}, b_1) == True{} : Bool} -> {Bq.Nat.le(a_0, b_1) == True{} : Bool})))

def Bq.le_step_down(a_0, b_1, e_2):
  match b_1:
    case Zero{}:
      (apply_253 = {(a_0 => \{}) : (@-a_0: Nat -> (@+___1: Empty -> {Bq.Nat.le(a_0, 0n) == True{} : Bool}))}; apply_253(a_0, Bq.Bool.false_ne_true(e_2)))
    case Succ{field_336}:
      Bq.le_succ_r(a_0, field_336, e_2)

law Bq.walk_bounds_go:
  (@+w_0: Nat -> (@+h_1: Nat -> (@+x_2: Nat -> (@+y_3: Nat -> (@+d_4: Bq.Dir -> (@+ex_5: {Bq.Nat.lt(x_2, w_0) == True{} : Bool} -> (@+ey_6: {Bq.Nat.lt(y_3, h_1) == True{} : Bool} -> {Bq.Bool.and(Bq.Nat.lt(Bq.walk_x(w_0, x_2, d_4), w_0), Bq.Nat.lt(Bq.walk_y(h_1, y_3, d_4), h_1)) == True{} : Bool})))))))

def Bq.walk_bounds_go(w_0, h_1, x_2, y_3, d_4, ex_5, ey_6):
  match d_4:
    case Bq.Dir.DL{}:
      (apply_254 = {(w_0 => (y_1 => (h_2 => \{Zero: (ex_3 => (ey_4 => Bq.and_intro(Bq.Nat.lt(0n, w_0), Bq.Nat.lt(y_1, h_2), ex_3, ey_4))); \{Succ: (p_3 => (ex_4 => (ey_5 => Bq.and_intro(Bq.Nat.lt(p_3, w_0), Bq.Nat.lt(y_1, h_2), Bq.le_step_down(Succ{p_3}, w_0, ex_4), ey_5)))); \{}}}))) : (@+w_0: Nat -> (@+y_1: Nat -> (@+h_2: Nat -> (@+___3: Nat -> (@+ex_4: {Bq.Nat.le(Succ{___3}, w_0) == True{} : Bool} -> (@+ey_5: {Bq.Nat.le(Succ{y_1}, h_2) == True{} : Bool} -> {Bq.Bool.and(Bq.Nat.le(Succ{Bq.Nat.pred(___3)}, w_0), Bq.Nat.le(Succ{y_1}, h_2)) == True{} : Bool}))))))}; apply_254(w_0, y_3, h_1, x_2, ex_5, ey_6))
    case Bq.Dir.DR{}:
      (apply_255 = {(x_0 => (w_1 => (y_2 => (h_3 => \{True: (t_4 => (ex_5 => (ey_6 => Bq.and_intro(Bq.Nat.lt(Succ{x_0}, w_1), Bq.Nat.lt(y_2, h_3), t_4, ey_6)))); \{False: (t_4 => (ex_5 => (ey_6 => Bq.and_intro(Bq.Nat.lt(x_0, w_1), Bq.Nat.lt(y_2, h_3), ex_5, ey_6)))); \{}}})))) : (@+x_0: Nat -> (@+w_1: Nat -> (@+y_2: Nat -> (@+h_3: Nat -> (@+___4: Bool -> (@+_e_5: {Bq.Nat.le(Succ{Succ{x_0}}, w_1) == ___4 : Bool} -> (@+ex_6: {Bq.Nat.le(Succ{x_0}, w_1) == True{} : Bool} -> (@+ey_7: {Bq.Nat.le(Succ{y_2}, h_3) == True{} : Bool} -> {Bq.Bool.and(Bq.Nat.le(Succ{(apply_256 = {(x_0 => \{True: Succ{x_0}; \{False: x_0; \{}}}) : (@+x_0: Nat -> (@+___1: Bool -> Nat))}; apply_256(x_0, ___4))}, w_1), Bq.Nat.le(Succ{y_2}, h_3)) == True{} : Bool}))))))))}; apply_255(x_2, w_0, y_3, h_1, Bq.Nat.lt(Succ{x_2}, w_0), {==}, ex_5, ey_6))
    case Bq.Dir.DU{}:
      (apply_257 = {(x_0 => (w_1 => (h_2 => \{Zero: (ex_3 => (ey_4 => Bq.and_intro(Bq.Nat.lt(x_0, w_1), Bq.Nat.lt(0n, h_2), ex_3, ey_4))); \{Succ: (p_3 => (ex_4 => (ey_5 => Bq.and_intro(Bq.Nat.lt(x_0, w_1), Bq.Nat.lt(p_3, h_2), ex_4, Bq.le_step_down(Succ{p_3}, h_2, ey_5))))); \{}}}))) : (@+x_0: Nat -> (@+w_1: Nat -> (@+h_2: Nat -> (@+___3: Nat -> (@+ex_4: {Bq.Nat.le(Succ{x_0}, w_1) == True{} : Bool} -> (@+ey_5: {Bq.Nat.le(Succ{___3}, h_2) == True{} : Bool} -> {Bq.Bool.and(Bq.Nat.le(Succ{x_0}, w_1), Bq.Nat.le(Succ{Bq.Nat.pred(___3)}, h_2)) == True{} : Bool}))))))}; apply_257(x_2, w_0, h_1, y_3, ex_5, ey_6))
    case Bq.Dir.DD{}:
      (apply_258 = {(y_0 => (h_1 => (x_2 => (w_3 => \{True: (t_4 => (ex_5 => (ey_6 => Bq.and_intro(Bq.Nat.lt(x_2, w_3), Bq.Nat.lt(Succ{y_0}, h_1), ex_5, t_4)))); \{False: (t_4 => (ex_5 => (ey_6 => Bq.and_intro(Bq.Nat.lt(x_2, w_3), Bq.Nat.lt(y_0, h_1), ex_5, ey_6)))); \{}}})))) : (@+y_0: Nat -> (@+h_1: Nat -> (@+x_2: Nat -> (@+w_3: Nat -> (@+___4: Bool -> (@+_e_5: {Bq.Nat.le(Succ{Succ{y_0}}, h_1) == ___4 : Bool} -> (@+ex_6: {Bq.Nat.le(Succ{x_2}, w_3) == True{} : Bool} -> (@+ey_7: {Bq.Nat.le(Succ{y_0}, h_1) == True{} : Bool} -> {Bq.Bool.and(Bq.Nat.le(Succ{x_2}, w_3), Bq.Nat.le(Succ{(apply_259 = {(y_0 => \{True: Succ{y_0}; \{False: y_0; \{}}}) : (@+y_0: Nat -> (@+___1: Bool -> Nat))}; apply_259(y_0, ___4))}, h_1)) == True{} : Bool}))))))))}; apply_258(y_3, h_1, x_2, w_0, Bq.Nat.lt(Succ{y_3}, h_1), {==}, ex_5, ey_6))

law Bq.walk_stays_in_bounds:
  (@+w_0: Nat -> (@+h_1: Nat -> (@+x_2: Nat -> (@+__3: {Bq.Nat.lt(x_2, w_0) == True{} : Bool} -> (@+y_4: Nat -> (@+__5: {Bq.Nat.lt(y_4, h_1) == True{} : Bool} -> (@+d_6: Bq.Dir -> {Bq.Bool.and(Bq.Nat.lt(Bq.walk_x(w_0, x_2, d_6), w_0), Bq.Nat.lt(Bq.walk_y(h_1, y_4, d_6), h_1)) == True{} : Bool})))))))

def Bq.walk_stays_in_bounds(w_0, h_1, x_2, __3, y_4, __5, d_6):
  Bq.walk_bounds_go(w_0, h_1, x_2, y_4, d_6, __3, __5)

law Bq.Bool.or:
  (@+a_0: Bool -> (@+b_1: Bool -> Bool))

def Bq.Bool.or(a_0, b_1):
  match a_0:
    case True{}:
      True{}
    case False{}:
      b_1

law Bq.Nat.eq:
  (@+a_0: Nat -> (@+b_1: Nat -> Bool))

def Bq.Nat.eq(a_0, b_1):
  match a_0:
    case Zero{}:
      match b_1:
        case Zero{}:
          True{}
        case Succ{field_337}:
          False{}
    case Succ{field_338}:
      match b_1:
        case Zero{}:
          False{}
        case Succ{field_339}:
          Bq.Nat.eq(field_338, field_339)

law Bq.near:
  (@+a_0: Nat -> (@+b_1: Nat -> Bool))

def Bq.near(a_0, b_1):
  Bq.Bool.or(Bq.Nat.eq(a_0, b_1), Bq.Bool.or(Bq.Nat.eq(Succ{a_0}, b_1), Bq.Nat.eq(a_0, Succ{b_1})))

law Bq.Nat.eq_refl:
  (@+a_0: Nat -> {Bq.Nat.eq(a_0, a_0) == True{} : Bool})

def Bq.Nat.eq_refl(a_0):
  match a_0:
    case Zero{}:
      {==}
    case Succ{field_340}:
      Bq.Nat.eq_refl(field_340)

law Bq.near_self:
  (@+x_0: Nat -> {Bq.near(x_0, x_0) == True{} : Bool})

def Bq.near_self(x_0):
  (%Equal.sym(Bool, Bq.Nat.eq(x_0, x_0), True{}, Bq.Nat.eq_refl(x_0)) : {Bq.Bool.or(_, Bq.Bool.or(Bq.Nat.eq(Succ{x_0}, x_0), Bq.Nat.eq(x_0, Succ{x_0}))) == True{} : Bool}; {==})

law Bq.neq_succ:
  (@+x_0: Nat -> {Bq.Nat.eq(Succ{x_0}, x_0) == False{} : Bool})

def Bq.neq_succ(x_0):
  match x_0:
    case Zero{}:
      {==}
    case Succ{field_341}:
      Bq.neq_succ(field_341)

law Bq.neq_succ2:
  (@+x_0: Nat -> {Bq.Nat.eq(Succ{Succ{x_0}}, x_0) == False{} : Bool})

def Bq.neq_succ2(x_0):
  match x_0:
    case Zero{}:
      {==}
    case Succ{field_342}:
      Bq.neq_succ2(field_342)

law Bq.near_pred:
  (@+x_0: Nat -> {Bq.near(x_0, Bq.Nat.pred(x_0)) == True{} : Bool})

def Bq.near_pred(x_0):
  match x_0:
    case Zero{}:
      {==}
    case Succ{field_343}:
      (%Equal.sym(Bool, Bq.Nat.eq(Succ{field_343}, field_343), False{}, Bq.neq_succ(field_343)) : {Bq.Bool.or(_, Bq.Bool.or(Bq.Nat.eq(Succ{Succ{field_343}}, field_343), Bq.Nat.eq(field_343, field_343))) == True{} : Bool}; (%Equal.sym(Bool, Bq.Nat.eq(Succ{Succ{field_343}}, field_343), False{}, Bq.neq_succ2(field_343)) : {Bq.Bool.or(_, Bq.Nat.eq(field_343, field_343)) == True{} : Bool}; (%Equal.sym(Bool, Bq.Nat.eq(field_343, field_343), True{}, Bq.Nat.eq_refl(field_343)) : {_ == True{} : Bool}; {==})))

law Bq.neq_succ_r:
  (@+x_0: Nat -> {Bq.Nat.eq(x_0, Succ{x_0}) == False{} : Bool})

def Bq.neq_succ_r(x_0):
  match x_0:
    case Zero{}:
      {==}
    case Succ{field_344}:
      Bq.neq_succ_r(field_344)

law Bq.near_succ:
  (@+x_0: Nat -> {Bq.near(x_0, Succ{x_0}) == True{} : Bool})

def Bq.near_succ(x_0):
  (%Equal.sym(Bool, Bq.Nat.eq(x_0, Succ{x_0}), False{}, Bq.neq_succ_r(x_0)) : {Bq.Bool.or(_, Bq.Bool.or(Bq.Nat.eq(x_0, x_0), Bq.Nat.eq(x_0, Succ{Succ{x_0}}))) == True{} : Bool}; (%Equal.sym(Bool, Bq.Nat.eq(x_0, x_0), True{}, Bq.Nat.eq_refl(x_0)) : {Bq.Bool.or(_, Bq.Nat.eq(x_0, Succ{Succ{x_0}})) == True{} : Bool}; {==}))

law Bq.walk_is_adjacent:
  (@+w_0: Nat -> (@+h_1: Nat -> (@+x_2: Nat -> (@+y_3: Nat -> (@+d_4: Bq.Dir -> {Bq.Bool.and(Bq.near(x_2, Bq.walk_x(w_0, x_2, d_4)), Bq.near(y_3, Bq.walk_y(h_1, y_3, d_4))) == True{} : Bool})))))

def Bq.walk_is_adjacent(w_0, h_1, x_2, y_3, d_4):
  match d_4:
    case Bq.Dir.DU{}:
      Bq.and_intro(Bq.near(x_2, x_2), Bq.near(y_3, Bq.Nat.pred(y_3)), Bq.near_self(x_2), Bq.near_pred(y_3))
    case Bq.Dir.DD{}:
      (apply_260 = {(x_0 => (y_1 => \{True: Bq.and_intro(Bq.near(x_0, x_0), Bq.near(y_1, Succ{y_1}), Bq.near_self(x_0), Bq.near_succ(y_1)); \{False: Bq.and_intro(Bq.near(x_0, x_0), Bq.near(y_1, y_1), Bq.near_self(x_0), Bq.near_self(y_1)); \{}}})) : (@+x_0: Nat -> (@+y_1: Nat -> (@+___2: Bool -> {Bq.Bool.and(Bq.Bool.or(Bq.Nat.eq(x_0, x_0), Bq.Bool.or(Bq.Nat.eq(Succ{x_0}, x_0), Bq.Nat.eq(x_0, Succ{x_0}))), Bq.Bool.or(Bq.Nat.eq(y_1, (apply_261 = {(y_0 => \{True: Succ{y_0}; \{False: y_0; \{}}}) : (@+y_0: Nat -> (@+___1: Bool -> Nat))}; apply_261(y_1, ___2))), Bq.Bool.or(Bq.Nat.eq(Succ{y_1}, (apply_262 = {(y_0 => \{True: Succ{y_0}; \{False: y_0; \{}}}) : (@+y_0: Nat -> (@+___1: Bool -> Nat))}; apply_262(y_1, ___2))), Bq.Nat.eq(y_1, Succ{(apply_263 = {(y_0 => \{True: Succ{y_0}; \{False: y_0; \{}}}) : (@+y_0: Nat -> (@+___1: Bool -> Nat))}; apply_263(y_1, ___2))})))) == True{} : Bool})))}; apply_260(x_2, y_3, Bq.Nat.lt(Succ{y_3}, h_1)))
    case Bq.Dir.DL{}:
      Bq.and_intro(Bq.near(x_2, Bq.Nat.pred(x_2)), Bq.near(y_3, y_3), Bq.near_pred(x_2), Bq.near_self(y_3))
    case Bq.Dir.DR{}:
      (apply_264 = {(x_0 => (y_1 => \{True: Bq.and_intro(Bq.near(x_0, Succ{x_0}), Bq.near(y_1, y_1), Bq.near_succ(x_0), Bq.near_self(y_1)); \{False: Bq.and_intro(Bq.near(x_0, x_0), Bq.near(y_1, y_1), Bq.near_self(x_0), Bq.near_self(y_1)); \{}}})) : (@+x_0: Nat -> (@+y_1: Nat -> (@+___2: Bool -> {Bq.Bool.and(Bq.Bool.or(Bq.Nat.eq(x_0, (apply_265 = {(x_0 => \{True: Succ{x_0}; \{False: x_0; \{}}}) : (@+x_0: Nat -> (@+___1: Bool -> Nat))}; apply_265(x_0, ___2))), Bq.Bool.or(Bq.Nat.eq(Succ{x_0}, (apply_266 = {(x_0 => \{True: Succ{x_0}; \{False: x_0; \{}}}) : (@+x_0: Nat -> (@+___1: Bool -> Nat))}; apply_266(x_0, ___2))), Bq.Nat.eq(x_0, Succ{(apply_267 = {(x_0 => \{True: Succ{x_0}; \{False: x_0; \{}}}) : (@+x_0: Nat -> (@+___1: Bool -> Nat))}; apply_267(x_0, ___2))}))), Bq.Bool.or(Bq.Nat.eq(y_1, y_1), Bq.Bool.or(Bq.Nat.eq(Succ{y_1}, y_1), Bq.Nat.eq(y_1, Succ{y_1})))) == True{} : Bool})))}; apply_264(x_2, y_3, Bq.Nat.lt(Succ{x_2}, w_0)))
