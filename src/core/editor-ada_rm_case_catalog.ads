package Editor.Ada_RM_Case_Catalog is

   type RM_Case_Campaign is
     (Campaign_Gap_Burn_Down,
      Campaign_Remaining_Gap_Remediation,
      Campaign_Unknown);

   function Campaign_For_Case (Case_Number : Natural) return RM_Case_Campaign;
   function Campaign_Label (Campaign : RM_Case_Campaign) return String;
   function Stable_Case_Label (Case_Number : Natural) return String;

end Editor.Ada_RM_Case_Catalog;
