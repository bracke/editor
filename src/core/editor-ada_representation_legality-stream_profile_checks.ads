with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Direct_Visibility;

package Editor.Ada_Representation_Legality.Stream_Profile_Checks is

   function Stream_Profile_Conforms
     (Kind    : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Profile : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info) return Boolean;
   function Unique_Visible_Declaration
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result;

end Editor.Ada_Representation_Legality.Stream_Profile_Checks;
