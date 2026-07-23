package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types is

   procedure Require_Phase
     (Ready : Boolean;
      Name  : String)
   is
   begin
      if not Ready then
         raise Program_Error with
           "projection phase dependency not satisfied: " & Name;
      end if;
   end Require_Phase;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
