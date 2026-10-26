from app import main


def test_main():
    result = main()
    assert result == "Python Docker CI Demo is running successfully!"