package body Editor.Ada_RM_Case_Catalog is

   function Campaign_For_Case (Case_Number : Natural) return RM_Case_Campaign is
   begin
      if Case_Number in 1343 .. 1366 then
         return Campaign_Gap_Burn_Down;
      elsif Case_Number in 1367 .. 1428 then
         return Campaign_Remaining_Gap_Remediation;
      else
         return Campaign_Unknown;
      end if;
   end Campaign_For_Case;

   function Campaign_Label (Campaign : RM_Case_Campaign) return String is
   begin
      case Campaign is
         when Campaign_Gap_Burn_Down =>
            return "rm-gap-burn-down";
         when Campaign_Remaining_Gap_Remediation =>
            return "rm-remaining-gap-remediation";
         when Campaign_Unknown =>
            return "rm-case-unknown";
      end case;
   end Campaign_Label;

   function Stable_Case_Label (Case_Number : Natural) return String is
      Image : constant String := Natural'Image (Case_Number);
   begin
      return Campaign_Label (Campaign_For_Case (Case_Number))
        & ":" & Image (Image'First + 1 .. Image'Last);
   end Stable_Case_Label;

end Editor.Ada_RM_Case_Catalog;
