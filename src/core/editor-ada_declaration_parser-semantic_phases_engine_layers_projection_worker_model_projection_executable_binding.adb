with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
with Editor.Ada_Syntax_Tree;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Executable_Binding is

   package Common_Phase_Types renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;

   procedure Run
     (Phase                  : in out Context;
      Facts                  : Publication.Context;
      Analysis               : in out Editor.Ada_Language_Model.Analysis_Result)
   is
      use Editor.Ada_Language_Model;
      use Editor.Text_Helpers;
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      Common_Phase_Types.Require_Phase
        (Publication.Facts_Are_Collected (Facts),
         "executable binding requires publication facts");

      for I in 1 .. Facts.Metadata_Fact_Count loop
         declare
            M : constant Common_Phase_Types.Metadata_Fact_Info :=
              Facts.Metadata_Facts (I);
         begin
            if M.Kind = Editor.Ada_Syntax_Tree.Node_Generic_Actual_Part then
               declare
                  Flags : Declaration_Flags := (others => False);
                  Owner : Symbol_Id := M.Owner;
                  Label : constant String := To_String (M.Label_Text);

                  function Instantiation_On_Line return Symbol_Id is
                  begin
                     for Index in 1 .. Symbol_Count (Analysis) loop
                        declare
                           S : constant Symbol_Info := Symbol_At (Analysis, Index);
                        begin
                           if S.Kind = Symbol_Instantiation
                             and then S.Source_Span.Start_Line =
                               M.Source_Span.Start_Line
                           then
                              return S.Id;
                           end if;
                        end;
                     end loop;
                     return No_Symbol;
                  end Instantiation_On_Line;

                  procedure Add_Positional_Actuals_From_Label is
                     First : Natural := Label'First;
                     Depth : Natural := 0;

                     procedure Add_Segment (Last : Natural) is
                        Actual : constant String := Trim (Label (First .. Last));
                     begin
                        if Actual /= "" then
                           Add_Generic_Actual
                             (Analysis,
                              Instance_Symbol => Owner,
                              Formal_Name     => "",
                              Actual_Name     => Actual,
                              Position        =>
                                Generic_Actual_Count (Analysis, Owner) + 1,
                              Source_Span     =>
                                Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
                                  .To_Model_Range (M.Source_Span));
                        end if;
                     end Add_Segment;
                  begin
                     if Owner = No_Symbol
                       or else Label = ""
                       or else M.Has_Generic_Association_Children
                     then
                        return;
                     end if;

                     for I in Label'Range loop
                        if Label (I) = '(' then
                           Depth := Depth + 1;
                        elsif Label (I) = ')' and then Depth > 0 then
                           Depth := Depth - 1;
                        elsif Label (I) = ',' and then Depth = 0 then
                           if I > First then
                              Add_Segment (I - 1);
                           end if;
                           First := I + 1;
                        end if;
                     end loop;

                     if First <= Label'Last then
                        Add_Segment (Label'Last);
                     end if;
                  end Add_Positional_Actuals_From_Label;
               begin
                  if not (Owner /= No_Symbol
                          and then Symbol (Analysis, Owner).Kind =
                            Symbol_Instantiation)
                  then
                     Owner := Instantiation_On_Line;
                     if Owner = No_Symbol then
                        Owner := M.Owner;
                     end if;
                  end if;
                  Flags.Has_Generic_Actual_Part_Metadata := True;
                  if Owner /= No_Symbol then
                     Merge_Symbol_Flags (Analysis, Owner, Flags);
                     Add_Positional_Actuals_From_Label;
                     Phase.Generic_Actual_Parts_Applied :=
                       Phase.Generic_Actual_Parts_Applied + 1;
                  end if;
               end;
            elsif M.Kind = Editor.Ada_Syntax_Tree.Node_Generic_Actual_Association then
               if M.Owner /= No_Symbol and then To_String (M.Generic_Actual) /= "" then
                  Add_Generic_Actual
                    (Analysis,
                     Instance_Symbol => M.Owner,
                     Formal_Name     => To_String (M.Generic_Formal),
                     Actual_Name     => To_String (M.Generic_Actual),
                     Position        =>
                       Generic_Actual_Count (Analysis, M.Owner) + 1,
                     Source_Span     =>
                       Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
                         .To_Model_Range (M.Source_Span));
                  Phase.Generic_Actual_Associations_Applied :=
                    Phase.Generic_Actual_Associations_Applied + 1;
               end if;
            end if;
         end;
      end loop;

      Phase.Completed := True;
   end Run;

   function Is_Complete (Phase : Context) return Boolean is
   begin
      return Phase.Completed;
   end Is_Complete;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Executable_Binding;
