package Editor.Ada_Representation_Legality.Interfacing_Checks is

   function Import_Export_Enabled_For_Target
     (Model  : Representation_Legality_Model;
      Target : String) return Boolean;
   function Has_Opposite_Enabled_Import_Export
     (Model : Representation_Legality_Model;
      Info  : Representation_Legality_Info) return Boolean;
   procedure Finalize_Interfacing_Conflicts
     (Model : in out Representation_Legality_Model);

end Editor.Ada_Representation_Legality.Interfacing_Checks;
