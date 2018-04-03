function in =  myinput(prompt)
   try 
       in = input(prompt);
   catch
       in = input(strcat('Bitte geben Sie nur Zahlen ein!', prompt));
   end
end