with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types.Status_Helpers;
with Editor.Ada_Language_Model;

package body Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement is

   function Normalize (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Normalize;

   function Cross_Unit_Selected_Subtype
     (Index    : Editor.Ada_Project_Index.Index_State;
      Path     : String;
      Selector : String) return String
   is
      Wanted : constant String := Editor.Ada_Language_Model.Normalize_Name (Selector);
   begin
      if Path'Length = 0 or else Wanted'Length = 0 then
         return "";
      end if;

      for File_Index in 1 .. Editor.Ada_Project_Index.File_Count (Index) loop
         declare
            Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
              Editor.Ada_Project_Index.File_Key_At (Index, File_Index);
         begin
            if To_String (Key.Path) = Path then
               declare
                  Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
                    Editor.Ada_Project_Index.File_Analysis_At (Index, File_Index);
               begin
                  for Symbol_Index in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
                     declare
                        Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                          Editor.Ada_Language_Model.Symbol_At
                            (Analysis, Symbol_Index);
                     begin
                        if To_String (Symbol.Normalized_Name) = Wanted then
                           if To_String (Symbol.Target_Name)'Length > 0 then
                              return To_String (Symbol.Target_Name);
                           else
                              return To_String (Symbol.Name);
                           end if;
                        end if;
                     end;
                  end loop;
               end;

               return "";
            end if;
         end;
      end loop;

      return "";
   end Cross_Unit_Selected_Subtype;

end Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement;
