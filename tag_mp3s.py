import eyed3
import csv
import pandas as pd
import os


##os.getcwd()

def main():
    # args = sys.argv[1:]
    # folder = str(args[0])
    folder = str(67)
    path_out = 'c:/Users/halatm/Desktop/git/cuentame_preprocess/datos/mp3/' + folder + '/out/'
    resumen = pd.read_csv(path_out + 'resumen_libro.csv', sep=';').iloc[0]
    print(resumen)
    autor = resumen.fakeAuthor
    titulo = resumen.fakeTitle

    os.chdir(path_out)

    # pd.set_option('display.width', 400)
    # pd.set_option('display.max_columns', 10)
    # pd.set_option('display.max_columns', None)

    a = pd.read_csv('summary.csv')
    a.head(5)

    for index, row in a.iterrows():
        print(row['titulo'], row['from'], row['filename.ok'])
        audiofile = eyed3.load(row['filename.ok'])
        audiofile.tag.artist = autor
        audiofile.tag.album = titulo
        audiofile.tag.album_artist = autor
        audiofile.tag.title = row['fake.title']
        audiofile.tag.track_num = row['id']

        audiofile.tag.save()


if __name__ == "__main__":
    main()
