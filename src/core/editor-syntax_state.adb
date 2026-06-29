with Editor.Syntax;
package body Editor.Syntax_State is
   use type Editor.Syntax.Lexical_State;

   function Is_Stateful (State : Line_Start_State) return Boolean is
   begin
      return State /= Editor.Syntax.Normal_State;
   end Is_Stateful;

end Editor.Syntax_State;
