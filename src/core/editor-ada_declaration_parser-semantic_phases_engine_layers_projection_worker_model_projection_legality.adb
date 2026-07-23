with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Legality is

   package Common_Phase_Types renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;

   procedure Run
     (Phase                      : in out Context;
      Facts                      : Publication.Context;
      Analysis                   : in out Editor.Ada_Language_Model.Analysis_Result;
      Tree                       : Editor.Ada_Syntax_Tree.Tree_Type;
      Representation_Context     :
        Editor.Ada_Declaration_Parser.Representation_Application.Application_Context;
      Target_Static_Metadata_Applied : Boolean;
      Apply_Metadata_To_Target   : not null access procedure
        (Target_Name : String;
         Flags       : Editor.Ada_Language_Model.Declaration_Flags))
   is
      use Editor.Ada_Language_Model;
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      Common_Phase_Types.Require_Phase
        (Target_Static_Metadata_Applied,
         "legality requires target derivation");
      Common_Phase_Types.Require_Phase
        (Publication.Facts_Are_Collected (Facts),
         "legality requires publication facts");

      for I in 1 .. Facts.Metadata_Fact_Count loop
         declare
            M : constant Common_Phase_Types.Metadata_Fact_Info :=
              Facts.Metadata_Facts (I);
         begin
            if M.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Clause then
               declare
                  Flags : Declaration_Flags := (others => False);
                  Target : constant String :=
                    To_String (M.Representation_Target_Text);
               begin
                  Flags.Has_Representation_Clause := True;
                  if M.Owner /= No_Symbol then
                     Merge_Symbol_Flags (Analysis, M.Owner, Flags);
                  elsif Target /= "" then
                     Apply_Metadata_To_Target (Target, Flags);
                  end if;
                  Editor.Ada_Declaration_Parser.Representation_Application
                    .Apply_General_Representation_Clause
                      (Representation_Context, Tree, Analysis, M.Node);
                  Phase.Representation_Facts_Applied :=
                    Phase.Representation_Facts_Applied + 1;
               end;
            elsif M.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Component_Clause then
               declare
                  Flags : Declaration_Flags := (others => False);
               begin
                  Flags.Has_Representation_Clause := True;
                  if M.Owner /= No_Symbol then
                     Merge_Symbol_Flags (Analysis, M.Owner, Flags);
                  elsif M.Representation_Target_Id /= No_Symbol then
                     Merge_Symbol_Flags
                       (Analysis, M.Representation_Target_Id, Flags);
                  end if;
                  Editor.Ada_Declaration_Parser.Representation_Application
                    .Apply_Record_Representation_Component
                      (Representation_Context, Analysis, M.Node);
                  Phase.Representation_Facts_Applied :=
                    Phase.Representation_Facts_Applied + 1;
               end;
            elsif M.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Mod_Clause then
               declare
                  Flags : Declaration_Flags := (others => False);
               begin
                  Flags.Has_Representation_Clause := True;
                  if M.Owner /= No_Symbol then
                     Merge_Symbol_Flags (Analysis, M.Owner, Flags);
                  elsif M.Representation_Target_Id /= No_Symbol then
                     Merge_Symbol_Flags
                       (Analysis, M.Representation_Target_Id, Flags);
                  end if;
                  Editor.Ada_Declaration_Parser.Representation_Application
                    .Apply_Record_Representation_Mod_Clause
                      (Representation_Context, Analysis, M.Node);
                  Phase.Representation_Facts_Applied :=
                    Phase.Representation_Facts_Applied + 1;
               end;
            end if;
         end;
      end loop;

      Phase.Completed := True;
   end Run;

   function Is_Complete (Phase : Context) return Boolean is
   begin
      return Phase.Completed;
   end Is_Complete;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Legality;
